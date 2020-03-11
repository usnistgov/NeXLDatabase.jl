using SQLite
using NeXLCore

struct DBUnknown
    quant::Int
    spectrum::DBSpectrum
    composition::Union{Material,Missing}
end

struct DBReference
    quant::Int
    spectrum::DBSpectrum
    elements::Vector{Element}
    reffor::Vector{Element}
end

struct DBFitSpectrum
    pkey::Int
    name::String
    project::DBProject
    elements::Vector{Element}
    unknowns::Vector{DBUnknown}
    reffor::Vector{DBReference}
end

elmstostr(elms::Vector{Element}) = join(symbol.(elms),',')
strtoelms(str::String) = parse.(Element,strip.(split(str,',')))
