

struct PeriodicTable
    links::Dict{Element, String}
end

function asa(::Type{DataFrame}, pt::PeriodicTable)::DataFrame
    df = DataFrame(Markdown.MD,10,18)
    for y in 1:10, x in 1:18
        df[y,x]=md""
    end
    for z in elements
        link = get(link,z,nothing)
        df[z.ypos, z.xpos] = isnothing(link) ? Markdown.parse("$(z.symbol)") : Markdown.parse("[$(z.symbol)]($link)")
    end
    return df
end
