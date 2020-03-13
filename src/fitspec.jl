using SQLite
using NeXLCore
using IntervalSets

struct Reference
    spectrum::Spectrum
    intervals::Dict{Element,ClosedInterval}
end

struct FitSpectrum
    unknowns::Vector{Spectrum}
    references::Vector{Reference}
end

struct DBUnknown
    quant::Int
    spectrum::DBSpectrum
    composition::Union{Material,Missing}
end

struct DBReference
    quant::Int
    spectrum::DBSpectrum
    elements::Vector{Element}
    reffor::Dict{Element,ClosedInterval{Float64}}
end

struct DBFitSpectrum
    pkey::Int
    name::String
    project::DBProject
    elements::Vector{Element}
    unknowns::Vector{DBUnknown}
    reffor::Vector{DBReference}
end

_elmstostr(elms::Vector{Element}) = join(symbol.(elms),',')
_strtoelms(str::String) = parse.(Element,strip.(split(str,',')))

_intervalstostr(intervals::Dict{Element, Vector{ClosedInterval{Float64}}})::String =
    join((elm.symbol*"=("*join(repr.(i),',')*')' for (elm, i) in intervals),';')

function _strtointervals(str::String)
    ci(ss)::Vector{ClosedInterval{Float64}} =
        [ ClosedInterval(parse(Float64,i[1]), parse(Float64,i[2])) for i in split.(strip.(split(ss[2:end-1],',')),r"\.\.") ]
    ts = split.(split(str,";"),'=')
    return Dict( parse(Element,t[1]) => ci(t[2]) for t in ts)
end

function Base.write(db::SQLite.DB, ::DBFitSpectrum, name::String, projKey::Int, elms::Vector{Element}, unks::Vector{Spectrum}, refs::)
