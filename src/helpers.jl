
function constructFitSpectra(
    db::SQLite.DB,
    project::DBProject, # The project
    sample::DBSample,   # The sample containing the unknown
    unkComp::Union{Material,Missing},  # The unknown material or missing
    detector::DBDetector, # The detector on which the data was collected
    analyst::DBPerson, # The person who collected the data
    e0::Float64, # The beam energy for the unknown in eV
    measSpectra::Vector{String}, # The files containing the measured spectra
    refSpectra::Vector{Tuple{DBSample, Material, String, Float64, Vector{Element}}}, # The reference spectra (sample, material, filename, e0, extra elements)
    extraElms::AbstractVector{Element} = Element[], #
)::Int
    SQLite.transaction(db) do # All or nothing...
        elms = ismissing(unkComp) ? extraElms : append!(collect(keys(unkComp)), extraElms)
        fitspectra = write(db, DBFitSpectra, project.pkey, detector.pkey, elms)
        dt = now()
        for fn in measSpectra
            format, name = sniffFormat(fn), splitext(splitdir(fn)[2])[1]
            spec = write(db, DBSpectrum, detector, e0, unkComp, analyst, sample, dt, name, fn, format)
            write(db, NeXLDatabase.DBFitSpectrum, fitspectra, spec)
        end
        for (samp, std, fn, e0s, elms) in refSpectra
            format, name = sniffFormat(fn), splitext(splitdir(fn)[2])[1]
            spec = write(db, DBSpectrum, detector, e0s, std, analyst, sample, dt, name, fn, format)
            refelms = ismissing(std) ? elms : append!(collect(keys(std)), elms)
            ref = write(db, DBReference, fitspectra, spec, refelms)
        end
        return fitspectra
    end
end

function NeXLSpectrum.fit(db::SQLite.DB, ::Type{DBFitSpectra}, pkey::Int, unkcomp::Union{Material, Nothing}=nothing)::Vector{FilterFitResult}
    fs = read(db, NeXLDatabase.DBFitSpectra, pkey)
    unks = measured(fs)
    det = convert(BasicEDS, fs.detector)
    ff = buildfilter(det)
    e0 = NeXLSpectrum.sameproperty(unks, :BeamEnergy)
    frs = FilteredReference[]

    function filteredROIs(ref, elm)
        spec, elms = asa(Spectrum, ref.spectrum), ref.elements
        cxrl = charXRayLabels(spec, elm, elms, det, e0)
        return filter(cxrl, ff, 1.0 / dose(spec))
    end

    for elm in fs.elements
        for ref in filter(ref->elm in ref.elements, fs.refspectrum)
            append!(frs, filteredROIs(ref, elm))
        end
    end
    ress = fit(unks, ff, frs)
    if !isnothing(unkcomp)
        # Remove previous k-ratios for this DBFitSpectra
        DBInterface.execute(SQLite.Stmt(db, "DELETE FROM KRATIO WHERE FITSPEC=?;"), (pkey, ))
        for (unk, res) in zip(unks, ress)
            write(db, DBKRatio, fs, unk, unkcomp, res)
        end
    end
    return ress
end
