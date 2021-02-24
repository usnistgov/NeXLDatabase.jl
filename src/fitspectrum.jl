using SQLite
using NeXLCore
using IntervalSets

struct DBFitSpectrum
    campaign::Int
    spectrum::DBSpectrum
end

Base.show(io::IO, dbf::DBFitSpectrum) = print(io, "Fit[$(dbf.spectrum.name)]")

NeXLUncertainties.asa(::Type{Spectrum}, dbfs::DBFitSpectrum) = NeXLUncertainties.asa(Spectrum, dbfs.spectrum)

function NeXLUncertainties.asa(::Type{DataFrame}, refs::Vector{DBFitSpectrum})
    fm, sm, cm = Union{Float64, Missing}, Union{String, Missing}, Union{Material,Missing}
    spname, e0, lt, pc, comp = sm[], fm[],  fm[], fm[], cm[]
    for ref in refs
        spec = asa(Spectrum, ref)
        push!(spname, get(spec, :Name, missing))
        push!(e0, get(spec, :BeamEnergy, missing))
        push!(lt, get(spec, :LiveTime, missing))
        push!(pc, get(spec, :ProbeCurrent, missing))
        push!(comp, get(spec, :Composition, missing))
    end
    return DataFrame(Name=spname, BeamEnergy=e0, LiveTime=lt, ProbeCurrent=pc, Composition=comp)
end

function Base.write(db::SQLite.DB, ::Type{DBFitSpectrum}, campaign::Int, spectrum::Int)::Int
    stmt1 = SQLite.Stmt(db, "INSERT INTO FITSPECTRUM(CAMPAIGN, SPECTRUM ) VALUES ( ?, ? );")
    q = DBInterface.execute(stmt1, (campaign, spectrum))
    return DBInterface.lastrowid(q)
end


