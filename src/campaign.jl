using SQLite
using NeXLCore
using IntervalSets
"""
A `DBCampaign` represents a collection of measurements of the same material.  It includes
both the unknown spectra and the reference spectra necessary to fit it as well as some
contextual data.
"""
struct DBCampaign
    database::SQLite.DB
    pkey::Int
    project::DBProject
    detector::DBDetector
    elements::Vector{Element}
    material::Union{Missing, Material}
    disposition::String
    fitspectrum::Vector{DBFitSpectrum}
    refspectrum::Vector{DBReference}
end

function NeXLUncertainties.asa(::Type{DataFrame}, campaign::DBCampaign)
    prop, values = String[], String[]
    push!(prop, "Primary Key"), push!(values, "$(campaign.pkey)")
    push!(prop, "Project"), push!(values, repr(campaign.project))
    push!(prop, "Analyst"), push!(values, campaign.project.createdBy.name)
    push!(prop, "Elements"), push!(values, "$(_elmstostr(campaign.elements))")
    push!(prop, "Material"), push!(values, repr(campaign.material))
    push!(prop, "Disposition"), push!(values, campaign.disposition)
    res = DataFrame(Property=prop, Value=values)
    return vcat(res, asa(DataFrame, campaign.detector))
end

function Base.show(io::IO, campaign::DBCampaign)
    println(io, "      Index = $(campaign.pkey)")
    println(io, "    Project = $(repr(campaign.project))")
    println(io, "   Elements = $(_elmstostr(campaign.elements))")
    println(io, "   Detector = $(repr(campaign.detector))")
    if !ismissing(campaign.material)
        println(io, "   Material = $(repr(campaign.material))")
    end
    println(io, "Disposition = $(campaign.disposition)")
    print(io, "==== Unknowns ====")
    for dbf in campaign.fitspectrum
        print(io, "\n\t$dbf")
    end
    print(io, "\n==== References ====")
    for elm in campaign.elements
        print(io, "\n\t$(symbol(elm)) = $(join(dbreferences(campaign, elm),','))")
    end
end

function NeXLUncertainties.asa(::Type{DataFrame}, camps::AbstractVector{DBCampaign})
    nm(m::Missing) = "Unknown"
    nm(m::Material) = name(m)
    DataFrame(
        Key = [ camp.pkey for camp in camps ],
        Material = [ camp.material for camp in camps ],
        E0 = [ camp.fitspectrum[1].spectrum.beamenergy for camp in camps],
        Unknowns = [ length(camp.fitspectrum) for camp in camps ],
        References = [ join([ nm(ref.spectrum.composition) for ref in camp.refspectrum],", ") for camp in camps ],
        Project = [ repr(camp.project) for camp in camps ],
        Analyst = [ camp.project.createdBy.name for camp in camps ],
        Disposition = [camp.disposition for camp in camps ],
    )
end

"""
    measured(campaign::DBCampaign)::Vector{Spectrum}
Return a vector containing the spectra to be fit.
"""
measured(campaign::DBCampaign)::Vector{Spectrum} = map(fs -> asa(Spectrum, fs), campaign.fitspectrum)

"""
    references(campaign::DBFitSpectra, elm::Element)::Vector{Spectrum})
Return a vector of the spectra which could be used as references for the Element.
"""
NeXLSpectrum.references(campaign::DBCampaign, elm::Element)::Vector{Spectrum} = map(ref->asa(Spectrum,ref), dbreferences(campaign, elm))

"""
    dbreferences(campaign::DBCampaign, elm::Element)::Vector{DBReference}

Return a vector of the spectra which could be used as references for the Element as DBReference objects.
"""
dbreferences(campaign::DBCampaign, elm::Element)::Vector{DBReference} =
    collect(filter(rs -> elm in rs.elements, campaign.refspectrum))

NeXLCore.elms(campaign::DBCampaign) = campaign.elements

_elmstostr(elms::Vector{Element}) = join(symbol.(elms), ',')
_strtoelms(str::String) = parse.(Element, strip.(split(str, ',')))

function Base.write(db::SQLite.DB, ::Type{DBCampaign}, projKey::Int, detKey::Int, elms::Vector{Element}, matkey::Integer, disposition::String="Pending")::Int
    stmt1 = SQLite.Stmt(db, "INSERT INTO CAMPAIGN(PROJECT, DETECTOR, DISPOSITION, ELEMENTS, MATKEY ) VALUES( ?, ?, ?, ?, ?);")
    q = DBInterface.execute(stmt1, (projKey, detKey, disposition, _elmstostr(elms), matkey))
    return DBInterface.lastrowid(q)
end

function Base.read(db::SQLite.DB, ::Type{DBCampaign}, campaign::Int)::DBCampaign
    stmt1 = SQLite.Stmt(db, "SELECT * FROM CAMPAIGN WHERE PKEY=?;")
    q1 = DBInterface.execute(stmt1, (campaign,))
    if SQLite.done(q1)
        error("No fit spectra record with campaign = $campaign.")
    end
    r1 = SQLite.Row(q1)
    @assert r1[:PKEY] == campaign "Mismatching pkey in DBFitSpectrum"
    project = read(db, DBProject, r1[:PROJECT])
    detector = read(db, DBDetector, r1[:DETECTOR])
    elms = _strtoelms(r1[:ELEMENTS])
    material = r1[:MATKEY] != -1 ? read(db, Material, r1[:MATKEY]) : missing
    disposition = r1[:DISPOSITION]
    stmt2 = SQLite.Stmt(db, "SELECT * FROM FITSPECTRUM WHERE CAMPAIGN=?;")
    q2 = DBInterface.execute(stmt2, (campaign,))
    tobefit = DBFitSpectrum[]
    for r2 in q2
        @assert r2[:CAMPAIGN] == campaign
        spec = read(db, DBSpectrum, r2[:SPECTRUM])
        push!(tobefit, DBFitSpectrum(db, campaign, spec))
    end
    stmt3 = SQLite.Stmt(db, "SELECT * FROM REFERENCESPECTRUM WHERE CAMPAIGN=?;")
    q3 = DBInterface.execute(stmt3, (campaign,))
    refs = DBReference[]
    for r3 in q3
        @assert r3[:CAMPAIGN] == campaign
        spec = read(db, DBSpectrum, r3[:SPECTRUM])
        push!(refs, DBReference(db, r3[:PKEY], r3[:CAMPAIGN], spec, _strtoelms(r3[:ELEMENTS])))
    end
    return DBCampaign(db, campaign, project, detector, elms, material, disposition, tobefit, refs)
end

function kratios(campaign::DBCampaign, elm::Union{Element,Nothing}=nothing, mink::Float64=0.0)::Vector{DBKRatio}
    return findall(campaign.database, DBKRatio, campaign=campaign.pkey, elm=elm, mink=mink)
end

"""
    disposition(db::SQLite.DB, ::Type{DBCampaign}, campaign::Int)

Reports the disposition of this set of fitted spectra.

  * `"Pending"` - Entered in the database but not reviewed
  * `"Rejected: "*msg` - Rejected for the reason specified in `msg`
  * `"Accepted: "*msg` - Reviewed and accepted with optional `msg`
"""
function disposition(db::SQLite.DB, ::Type{DBCampaign}, campaign::Int)
    stmt1 = SQLite.Stmt(db, "SELECT DISPOSITION FROM CAMPAIGN WHERE PKEY=?;")
    q1 = DBInterface.execute(stmt1, (campaign,))
    if SQLite.done(q1)
        error("No fit spectra record with campaign = $campaign.")
    end
    return SQLite.Row(q1)[:DISPOSITION]
end
disposition(camp::DBCampaign) = camp.disposition

"""
    disposition!(db::SQLite.DB, ::Type{DBCampaign}, campaign::Int, value::String)

Sets the disposition of this set of fitted spectra.

  * `"Pending"` - Entered in the database but not reviewed
  * `"Rejected: "*msg` - Rejected for the reason specified in `msg`
  * `"Accepted: "*msg` - Reviewed and accepted with optional `msg`
"""
function disposition!(db::SQLite.DB, ::Type{DBCampaign}, campaign::Int, value::AbstractString)
    @assert isequal("Pending", value) || startswith(value, "Rejected") || startswith("Accepted") 
        "The disposition must be \"Pending\" or start with \"Rejected\" or \"Accepted\""
    stmt1 = SQLite.Stmt(db, "UPDATE CAMPAIGN SET DISPOSITION = ? WHERE PKEY=?;")
    DBInterface.execute(stmt1, (campaign, value))
    return value
end
function disposition!(campaign::DBCampaign, value::AbstractString)
    return disposition!(campaign.database, DBCampaign, campaign.pkey, value)
end


function Base.delete!(db::SQLite.DB, ::Type{DBCampaign}, campaign::Int)
    stmt1 = SQLite.Stmt(db, "DELETE FROM CAMPAIGN WHERE PKEY=?;")
    stmt2 = SQLite.Stmt(db, "DELETE FROM REFERENCESPECTRUM WHERE CAMPAIGN=?;")
    stmt3 = SQLite.Stmt(db, "DELETE FROM FITSPECTRUM WHERE CAMPAIGN=?;")
    stmt4 = SQLite.Stmt(db, "DELETE FROM KRATIO WHERE FITSPEC=?;")
    DBInterface.execute(stmt4, (campaign,))
    DBInterface.execute(stmt3, (campaign,))
    DBInterface.execute(stmt2, (campaign,))
    DBInterface.execute(stmt1, (campaign,))
end

function Base.delete!(campaign::DBCampaign)
    delete!(campaign.database, DBCampaign, campaign.pkey)
end

function NeXLUncertainties.asa(::Type{DataFrame}, db::SQLite.DB, ::Type{DBCampaign})
    stmt1 = SQLite.Stmt(db, "SELECT PKEY FROM CAMPAIGN")
    q1 = DBInterface.execute(stmt1)
    return SQLite.done(q1) ? DataFrame() : asa(DataFrame, [ read(db, DBCampaign, row[:PKEY]) for row in res ])
end

function Base.findall(db::SQLite.DB, ::Type{DBCampaign}; material::Union{String,Missing}=missing, project::Union{DBProject,Missing} = missing, det::Union{DBDetector,Missing}=missing)::Vector{DBCampaign}
    keys, args = String[], Any[]
    if !ismissing(material)
        matkey = find(db, Material, material)
        @assert matkey!=-1 "Unable to find the material named `$material`."
        push!(keys, "MATKEY=?")
        push!(args, matkey)
    end
    if !ismissing(project)
        push!(keys,"PROJECT=?")
        push!(args, project.pkey)
    end
    if !ismissing(det)
        push!(keys, "DETECTOR=?")
        push!(args, det.pkey)
    end
    if length(keys)==0
        @error "Please specify either a project or a detector."
    end
    stmt=SQLite.Stmt(db, "SELECT PKEY FROM CAMPAIGN WHERE $(join(keys," AND "));")
    q1 = DBInterface.execute(stmt, args)
    return [ read(db, DBCampaign, r[:PKEY] ) for r in q1 ]
end

"""
    NeXLMatrixCorrection.quantify(#
        db::SQLite.DB, #
        ::Type{DBCampaign}, #
        campaign::Int; #
        strip::AbstractVector{Element} = Element[],
		iteration::Iterator = Iterator(XPP,ReedFluorescence,Coating),
        kro::KRatioOptimizer = SimpleKRatioOptimizer(1.5),
    )::Vector{IterationResult}

Quantify the k-ratios in the database associated with te specified DBCampaign.
"""
function NeXLMatrixCorrection.quantify(#
    db::SQLite.DB, #
    ::Type{DBCampaign}, #
    campaign::Int; #
    args...
)::Vector{IterationResult}
    quantify(findall(db, DBKRatio, campaign=campaign, mink=0.0), args...)
end

function Base.write(
    db::SQLite.DB, #
    ::Type{DBCampaign}, #
    project::DBProject, # The project
    sample::DBSample,   # The sample containing the unknown
    unkComp::Union{Material,Missing},  # The unknown material or missing
    detector::DBDetector, # The detector on which the data was collected
    analyst::DBPerson, # The person who collected the data
    e0::Float64, # The beam energy for the unknown in eV
    measSpectra::Vector{String}, # The files containing the measured spectra
    refSpectra::Vector{Tuple{DBSample, Material{T,U}, String, Float64, Vector{Element}}}, # The reference spectra (sample, material, filename, e0, extra elements)
    extraElms::AbstractVector{Element} = Element[], #
)::Int where { T<:AbstractFloat, U<:AbstractFloat}
    SQLite.transaction(db) do # All or nothing...
        elms, matkey = if ismissing(unkComp)
            extraElms, -1
        else
            unique(append!(collect(keys(unkComp)), extraElms)), write(db, unkComp)
        end
        campaign = write(db, DBCampaign, project.pkey, detector.pkey, elms, matkey)
        dt = now()
        for fn in measSpectra
            format, name = sniffFormat(fn), splitext(splitdir(fn)[2])[1]
            spec = write(db, DBSpectrum, detector, e0, unkComp, analyst, sample, dt, name, fn, format)
            write(db, NeXLDatabase.DBFitSpectrum, campaign, spec)
        end
        for (samp, std, fn, e0s, elms) in refSpectra
            format, name = sniffFormat(fn), splitext(splitdir(fn)[2])[1]
            spec = write(db, DBSpectrum, detector, e0s, std, analyst, sample, dt, name, fn, format)
            refelms = ismissing(std) ? elms : append!(collect(keys(std)), elms)
            ref = write(db, DBReference, campaign, spec, refelms)
        end
        return campaign
    end
end

"""
    NeXLSpectrum.fit_spectrum(db::SQLite.DB, ::Type{DBCampaign}, campaign::Int, unkcomp::Union{Material, Missing}=missing, update=true)

Fit a collection of spectra from the database against the reference spectra associated in the database with it.  If 
`unkcomp` is provided then previous k-ratio results are deleted and the new k-ratio results are written to the database.
"""
function NeXLSpectrum.fit_spectrum(db::SQLite.DB, ::Type{DBCampaign}, campaign::Int, unkcomp::Union{Material, Missing}=missing; update::Bool=true)::Vector{FilterFitResult}
    fs = read(db, DBCampaign, campaign)
    unks = measured(fs)
    det = convert(BasicEDS, fs.detector)
    refs =  NeXLSpectrum.ReferencePacket[]
    specs = [ asa(Spectrum, ref.spectrum) for ref in fs.refspectrum ]
    for elm in fs.elements
        # Make sure that the candidate reference material has some of this element
        for spec in filter(sp->haskey(sp,:Composition) && (value(sp[:Composition][elm]) > 0.01) , specs)
			push!(refs, reference(elm, spec))
		end
	end
	ffp = NeXLSpectrum.references(refs, det)
    ress = map(sp->fit_spectrum(sp, ffp), unks)
    update && SQLite.transaction(db) do
        # Remove previous k-ratios for this DBCampaign
        DBInterface.execute(SQLite.Stmt(db, "DELETE FROM KRATIO WHERE CAMPAIGN=?;"), (campaign, ))
        for (unk, res) in zip(unks, ress)
            # @show campaign, res
            write(db, DBKRatio, fs, unk, unkcomp, res)
        end
        true
    end
    return ress
end




