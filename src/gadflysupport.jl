using .Gadfly

using NeXLMatrixCorrection
using Colors

function Gadfly.plot(dbkrs::AbstractArray{DBKRatio}; mc::Type{<:MatrixCorrection}=XPP, fc::Type{<:FluorescenceCorrection}=ReedFluorescence)
    mfs, kok, dkok, color = String[], Float64[], Float64[], Color[]
    next=1
    matcolors=Dict{String,RGB{Float64}}()
    for dbkr in dbkrs
        kr, unkComp = asa(KRatio, dbkr), get(dbkr.measured, :Composition, missing)
        if hasminrequired(mc, kr.unkProps) && hasminrequired(fc, kr.unkProps) && #
            hasminrequired(mc, kr.stdProps) && hasminrequired(fc, kr.stdProps) && #
            (!isnothing(unkComp)) && (value(unkComp[kr.element]) > 0.0) && (value(kr.standard[kr.element]) > 0.0)
            try
                # Compute the k-ratio
                kc = gZAFc(kr, unkComp) * (value(unkComp[kr.element]) / value(kr.standard[kr.element]))
                push!(mfs, name(shell(brightest(kr.lines)))) # value(unkComp[kr.element]))
                push!(kok, value(kr.kratio) / kc)
                push!(dkok, σ(kr.kratio) / kc)
                matname = "$(kr.element) in $(name(unkComp)) $(kr.unkProps[:BeamEnergy]/1000.0) keV"
                if !haskey(matcolors,matname)
                    matcolors[matname]=NeXLPalette[next]
                    next+=1
                end
                push!(color, matcolors[matname])
            catch c
                @info "Failed on $dbkr - $c"
            end
        end
    end
    plot(x=mfs, y=kok, ymin=kok .- dkok, ymax=kok .+ dkok, color=color, Geom.errorbar, Stat.x_jitter(range=0.8),
        Guide.manual_color_key("Material", [ keys(matcolors)...], [ values(matcolors)...]), # Guide.yrug,
        Guide.xlabel("Shell"), Guide.ylabel("k[Measured]/k[Calculated]"), Scale.x_discrete(levels=["K","L","M"]),
        Coord.cartesian(xmin=1,xmax=3))
end
