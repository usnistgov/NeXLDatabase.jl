MaybeMaterial = Union{Material, Missing}

function constructFitSpectra(
    db::SQLite.DB,
    project::DBProject, # The project
    sample::DBSample,   # The sample containing the unknown
    unkComp::Union{Material,Missing},  # The unknown material or missing
    detector::DBDetector, # The detector on which the data was collected
    analyst::DBPerson, # The person who collected the data
    e0::Float64, # The beam energy for the unknown in eV
    unkSpectra::Vector{String}, # The files containing the unknown
    stdSpectra::Vector{Tuple{DBSample, Material, String, Float64, Vector{Element}}}, # The standard spectra (sample, material, filename, e0, extra elements)
    extraElms::AbstractVector{Element} = [], #
)::Int
    SQLite.transaction(db) do # All or nothing...
        elms = ismissing(unkComp) ? extraElms : append!(collect(keys(unkComp)), extraElms)
        fitspectra = write(db, DBFitSpectra, project.pkey, detector.pkey, elms)
        dt = now()
        for fn in unkSpectra
            format, name = sniffFormat(fn), splitext(splitdir(fn)[2])[1]
            spec = write(db, DBSpectrum, detector, e0, unkComp, analyst, sample, dt, name, fn, format)
            write(db, NeXLDatabase.DBFitSpectrum, fitspectra, spec)
        end
        for (samp, std, fn, e0s, elms) in stdSpectra
            format, name = sniffFormat(fn), splitext(splitdir(fn)[2])[1]
            spec = write(db, DBSpectrum, detector, e0s, std, analyst, sample, dt, name, fn, format)
            refelms = ismissing(std) ? elms : append!(collect(keys(std)), elms)
            ref = write(db, DBReference, fitspectra, spec, refelms)
        end
        return fitspectra
    end
end

function NeXLSpectrum.fit(db::SQLite.DB, ::Type{DBFitSpectra}, pkey::Int, writekrs::Bool=false)::Vector{FilterFitResult}
    fs = read(db, NeXLDatabase.DBFitSpectra, pkey)
    unks = unknowns(fs)
    det = convert(BasicEDS, fs.detector)
    ff = buildfilter(det)
    e0 = NeXLSpectrum.sameproperty(unks, :BeamEnergy)
    frs = FilteredReference[]

    function filteredROIs(ref, elm)
        spec, elms = asa(Spectrum, ref.spectrum), ref.elements
        cxrl = NeXLDatabase.charXRayLabels(spec, elm, elms, det, 0.5e-4, e0)
        return filter(cxrl, ff, 1.0 / dose(spec))
    end

    for elm in fs.elements
        for ref in filter(ref->elm in ref.elements, fs.refspectrum)
            append!(frs, filteredROIs(ref, elm))
        end
    end
    ress = fit(unks, ff, frs)
    if writekrs
        @assert all(unk->haskey(unk, :Composition), unknowns) "All the unknowns must have the :Composition defined."
        # Remove previous k-ratios for this DBFitSpectra
        execute(SQLite.Stmt(db, "DELETE FROM KRATIO WHERE FITSPEC=?;"), (pkey, ))
        for (res, unk) in zip(unknowns, ress)
            write(db, DBKratio, fs, unk, unk[:Composition], res)
        end
    end
    return ress
end
