using .Gadfly

using NeXLMatrixCorrection
using Colors

function Gadfly.plot(
    dbkrs::AbstractArray{DBKRatio};
    mc::Type{<:MatrixCorrection} = XPP,
    fc::Type{<:FluorescenceCorrection} = ReedFluorescence,
    palette = NeXLPalette,
)
    mfs, kok, dkok, color = String[], Float64[], Float64[], Color[]
    next = 0
    matcolors = Dict{String,RGB{Float64}}()
    for dbkr in dbkrs
        kr, unkComp = asa(KRatio, dbkr), get(dbkr.measured, :Composition, missing)
        if hasminrequired(mc, kr.unkProps) &&
           hasminrequired(fc, kr.unkProps) && #
           hasminrequired(mc, kr.stdProps) &&
           hasminrequired(fc, kr.stdProps) && #
           (!isnothing(unkComp)) &&
           (value(unkComp[kr.element]) > 0.0) &&
           (value(kr.standard[kr.element]) > 0.0)
            try
                # Compute the k-ratio
                kc = gZAFc(kr, unkComp) * (value(unkComp[kr.element]) / value(kr.standard[kr.element]))
                push!(mfs, name(shell(brightest(kr.lines)))) # value(unkComp[kr.element]))
                push!(kok, value(kr.kratio) / kc)
                push!(dkok, σ(kr.kratio) / kc)
                matname = "$(symbol(kr.element)) in $(name(unkComp)) $(kr.unkProps[:BeamEnergy]/1000.0) keV"
                if !haskey(matcolors, matname)
                    matcolors[matname] = palette[next+=1]
                end
                push!(color, matcolors[matname])
            catch c
                @info "Failed on $dbkr - $c"
            end
        end
    end
    if length(mfs)>0
        plot(
            x = mfs,
            y = kok,
            ymin = kok .- dkok,
            ymax = kok .+ dkok,
            color = color,
            Geom.errorbar,
            Stat.x_jitter(range = 0.8),
            Guide.manual_color_key("Material", collect(keys(matcolors)), collect(values(matcolors))), # Guide.yrug,
            Guide.xlabel("Shell"),
            Guide.ylabel("k[Measured]/k[$(repr(nameof(mc))[2:end])]"),
            Scale.x_discrete(levels = ["K", "L", "M"]),
            Coord.cartesian(xmin = 1, xmax = 3),
        )
    else
        return nothing
    end
end


function plot2(dbkrs::AbstractArray{DBKRatio}; palette = NeXLPalette)
    kok, dkok, color = Float64[], Float64[], Color[]
    ygroup = CharXRay[]
    matcolors = Dict{String,RGB{Float64}}()
    for dbkr in dbkrs
        kr, unkComp = asa(KRatio, dbkr), get(dbkr.measured, :Composition, missing)
        push!(kok, value(kr.kratio))
        push!(dkok, σ(kr.kratio))
        push!(ygroup, brightest(kr.lines))
        matname = "$(kr.element) in $(name(unkComp)) $(kr.unkProps[:BeamEnergy]/1000.0) keV"
        if !haskey(matcolors, matname)
            matcolors[matname] = palette[length(matcolors)+1]
        end
        push!(color, matcolors[matname])
    end
    @show
    plot(
        x = eachindex(kok),
        y = kok,
        ymin = kok .- dkok,
        ymax = kok .+ dkok,
        color = color,
        ygroup = ygroup, # Geom.errorbar, Stat.x_jitter(range=0.8),
        Geom.subplot_grid(Geom.errorbar, free_y_axis = true),
        Scale.ygroup(labels = cxr -> repr(cxr), levels = allcxrs),
        Guide.manual_color_key("Material", collect(keys(matcolors)), collect(values(matcolors))), # Guide.yrug,
        Guide.xlabel("Index"),
        Guide.ylabel("k[Measured]"),
    )
end

function plot2(
    krs::AbstractArray{DBKRatio};
    known::Union{Material,Missing} = missing,
    label::AbstractString = "Material",
    palette = NeXLPalette,
)
    allelms = sort(convert(Vector{Element}, collect(union(map(keys, mats)...))))
    elmcol = Dict(elm => palette[i] for (i, elm) in enumerate(allelms))
    xs, ymin, ymax, ygroups, colors = String[], Float64[], Float64[], Element[], Color[]
    for mat in mats
        append!(xs, [name(mat) for elm in keys(mat)])
        append!(ymin, [value(mat[elm]) - σ(mat[elm]) for elm in keys(mat)])
        append!(ymax, [value(mat[elm]) + σ(mat[elm]) for elm in keys(mat)])
        append!(colors, [elmcol[elm] for elm in keys(mat)])
        append!(ygroups, collect(keys(mat)))
    end
    plot(
        x = xs,
        ymin = ymin,
        ymax = ymax,
        color = colors,
        ygroup = ygroups,
        Geom.subplot_grid(Geom.errorbar, free_y_axis = true),
        Scale.ygroup(labels = elm -> symbol(elm), levels = allelms),
        Guide.manual_color_key("Material", collect(keys(matcolors)), collect(values(matcolors))),
        Guide.xlabel(label),
        Guide.ylabel("Mass Fraction by Element"),
    )
end
