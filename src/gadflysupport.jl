using .Gadfly

using NeXLMatrixCorrection
using Colors

"""
    Gadfly.plot(
        dbkrs::AbstractArray{DBKRatio};
        mc::Type{<:MatrixCorrection} = XPP,
        fc::Type{<:FluorescenceCorrection} = ReedFluorescence,
        palette = NeXLPalette,
        style::Symbol = :Ratio | :XY
    )
"""
function Gadfly.plot(
    dbkrs::AbstractArray{DBKRatio};
    mc::Type{<:MatrixCorrection} = XPP,
    fc::Type{<:FluorescenceCorrection} = ReedFluorescence,
    cc::Type{<:CoatingCorrection} = Coating,
    style::Symbol = :Ratio
)
    if style==:Ratio
        plot_ratio(dbkrs, mc, fc, cc)
    elseif style==:XY
        plot_xy(dbkrs, mc, fc)
    else
        plot(map(kr->asa(KRatio, kr), krs), mc, fc)
end

function plot_ratio(
    dbkrs::AbstractArray{DBKRatio},
    mc::Type{<:MatrixCorrection} = XPP,
    fc::Type{<:FluorescenceCorrection} = ReedFluorescence,
    cc::Type{<:CoatingCorrection} = Coating,
)
  name(m::Missing) = "Unknown"
  name(vc::AbstractVector{CharXRay}) = NeXLCore.name(vc, true)
  df = asa(DataFrame, dbkrs, withComputedKs=true, mc=mc, fc=fc, cc=cc)
  df[:, "Element"] = symbol.(element.(first.(df[:,"Lines"]))) 
  df[:, "Z"] = z.(element.(first.(df[:,"Lines"])))
  df[:, "Family"] = name.(df[:,"Lines"])
  df[:, "RU"] = map(r->uv(r["K"],r["ΔK"])/r["Kxpp"], eachrow(df))
  df[:, "Rmin"] = map(r-> value(r["RU"])-σ(r["RU"]), eachrow(df))
  df[:, "Rmax"] = map(r-> value(r["RU"])+σ(r["RU"]), eachrow(df))
  df[:,"Measurement"] = map(r->"$(NeXLCore.name(r["Cmeas"])) at $(r["E0meas"]/1000.0) keV using $(NeXLCore.name(r["Cref"]))", eachrow(df))
  df[:,"Rand"] = rand(nrow(df)) # To plot points in a randomized order.
  filter!(r->element(first(r[:Lines])) in keys(r[:Cmeas]), df)
  sort!(df, [:Family, :E0meas, :Z, :Rand])
  # yin, yax = something(ymin, 0.9*minimum(skipmissing(df[:,"Rmin"]))), something(ymax, 1.1*maximum(skipmissing(df[:,"Rmax"])))
  plot(df, xgroup="Family", x="Element", ymin="Rmin", ymax="Rmax", y="Ratio", color="Measurement", 
     # Coord.cartesian(ymin=yin, ymax=yax), Stat.x_jitter(range=1.0), # Neither seems to work... 
     Geom.subplot_grid(Geom.errorbar), Stat.x_jitter(range=1000.0))
end

function plot_xy(
    dbkrs::AbstractArray{DBKRatio},
    mc::Type{<:MatrixCorrection} = XPP,
    fc::Type{<:FluorescenceCorrection} = ReedFluorescence,
    cc::Type{<:CoatingCorrection} = Coating,
)
    x, y, dy, color = Float64[], Float64[], Float64[], String[]
    next = 0
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
                kc = gZAFc(kr, unkComp, mc=mc, fc=fc, cc=cc) * (value(unkComp[kr.element]) / value(kr.standard[kr.element]))
                push!(y, value(kr.kratio))
                push!(dy, σ(kr.kratio))
                push!(x, kc)
                push!(color, "$(symbol(kr.element)) $(name(shell(brightest(kr.xrays)))) in $(name(unkComp)) $(kr.unkProps[:BeamEnergy]/1000.0) keV")
            catch c
                @info "Failed on $dbkr - $c"
            end
        end
    end
    abline = Geom.abline(color="red", style=:dash)
    plot(
        x = x,
        y = y,
        ymin = y .- dy,
        ymax = y .+ dy,
        color = color,
        Geom.errorbar,
        Guide.xlabel("k[$(repr(nameof(mc))[2:end])]"),
        Guide.ylabel("k[Measured]"),
        Guide.colorkey(title="Measurement"),
        abline, intercept=[0.0],slope=[1.0],
    )
end

function plot2(dbkrs::AbstractArray{DBKRatio}; palette = NeXLPalette)
    kok, dkok, color = Float64[], Float64[], Color[]
    ygroup = CharXRay[]
    matcolors = Dict{String,RGB{Float64}}()
    for dbkr in dbkrs
        kr, unkComp = asa(KRatio, dbkr), get(dbkr.measured, :Composition, missing)
        push!(kok, value(kr.kratio))
        push!(dkok, σ(kr.kratio))
        push!(ygroup, brightest(kr.xrays))
        matname = "$(kr.element) in $(name(unkComp)) $(kr.unkProps[:BeamEnergy]/1000.0) keV"
        if !haskey(matcolors, matname)
            matcolors[matname] = palette[length(matcolors)+1]
        end
        push!(color, matcolors[matname])
    end
    plot(
        x = eachindex(kok),
        y = kok,
        ymin = kok .- dkok,
        ymax = kok .+ dkok,
        color = color,
        ygroup = ygroup, # Geom.errorbar, Stat.x_jitter(range=0.8),
        Geom.subplot_grid(Geom.errorbar, free_y_axis = true),
        Scale.ygroup(labels = cxr -> repr(cxr), levels = unique(ygroup)),
        Guide.manual_color_key("Material", collect(keys(matcolors)), collect(values(matcolors))), # Guide.yrug,
        Guide.xlabel("Index"),
        Guide.ylabel("k[Measured]"),
    )
end

function plot3(
    krs::AbstractArray{DBKRatio};
    label::AbstractString = "Material",
    palette = NeXLPalette,
)
    mats = unique(collect(dropmissing(map(dbkr->get(dbkr.measured,:Composition,missing), krs))))
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
        Guide.manual_color_key("Material", symbol.(collect(keys(elmcol))), collect(values(elmcol))),
        Guide.xlabel(label),
        Guide.ylabel("Mass Fraction by Element"),
    )
end

function plot4(krs::AbstractArray{DBKRatio})
    
end
