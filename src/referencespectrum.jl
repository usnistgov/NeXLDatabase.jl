struct DBReference
    pkey::Int
    campaign::Int
    spectrum::DBSpectrum
    elements::Vector{Element} # The elements evident in the reference spectrum
end

Base.show(io::IO, dbr::DBReference) =
    print(io, "Reference[$(dbr.spectrum.name) with $(join(symbol.(dbr.elements),','))]")

NeXLUncertainties.asa(::Type{Spectrum}, dbr::DBReference) = NeXLUncertainties.asa(Spectrum, dbr.spectrum)

function Base.write(db::SQLite.DB, ::Type{DBReference}, campaign::Int, spectrum::Int, elements::Vector{Element})::Int
    stmt1 = SQLite.Stmt(db, "INSERT INTO REFERENCESPECTRUM(CAMPAIGN, SPECTRUM, ELEMENTS) VALUES ( ?, ?, ? );")
    q = DBInterface.execute(stmt1, (campaign, spectrum, _elmstostr(elements)))
    return DBInterface.lastrowid(q)
end

function NeXLUncertainties.asa(::Type{DataFrame}, refs::Vector{DBReference})
    fm, sm, cm = Union{Float64, Missing}, Union{String, Missing}, Union{Material,Missing}
    elms, spname, e0, lt, pc, comp = String[], String[], fm[],  fm[], fm[], cm[]
    for ref in refs
        spec = asa(Spectrum, ref)
        push!(elms, _elmstostr(ref.elements))
        push!(spname, spec[:Name])
        push!(e0, get(spec, :BeamEnergy, missing))
        push!(lt, get(spec, :LiveTime, missing))
        push!(pc, get(spec, :ProbeCurrent, missing))
        push!(comp, get(spec, :Composition, missing))
    end
    return DataFrame(Elements=elms, Name=spname, BeamEnergy=e0, LiveTime=lt, ProbeCurrent=pc, Composition=comp)
end