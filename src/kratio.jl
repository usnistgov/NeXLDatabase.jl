using NeXLMatrixCorrection

struct DBKRatio
    database::SQLite.DB
    pkey::Int
    campaign::Int
    spectrum::Int
    primary::CharXRay
    xrays::Vector{CharXRay}
    mode::String
    measured::Dict{Symbol,Any}
    reference::Dict{Symbol,Any}
    kratio::UncertainValue
end

function Base.show(io::IO, kr::DBKRatio)
    print( io, "$(krname(kr)): $(kr.xrays)] = $(kr.kratio)")
end

function krname(kr::DBKRatio)
    nm = haskey(kr.measured, :Composition) ? name(kr.measured[:Composition]) : "Unspecified"
    return "K[($nm @ $(0.001*kr.measured[:BeamEnergy]) keV)/($(name(kr.reference[:Composition])) @ $(0.001*kr.reference[:BeamEnergy]) keV)"
end

function Base.read(db::SQLite.DB, ::Type{DBKRatio}, pkey::Int)::DBKRatio
    stmt = SQLite.Stmt(db, "SELECT * FROM KRATIO WHERE PKEY=?;")
    q = DBInterface.execute(stmt, (pkey,))
    SQLite.done(q) && error("There is no k-ratio with pkey = $(pkey).")
    r = SQLite.Row(q)
    primary = CharXRay(r[:ELEMENT], Transition(SubShell(r[:INNER]), SubShell(r[:OUTER])))
    xrays = map(s -> parse(CharXRay, s), split(r[:LINES], ","))
    meas = Dict{Symbol,Any}(:BeamEnergy => r[:MEASE0], :TakeOffAngle => r[:MEASTOA])
    if r[:MEASURED] != -1
        meas[:Composition] = read(db, Material, r[:MEASURED])
    end
    ref = Dict{Symbol,Any}(:BeamEnergy => r[:REFE0], :TakeOffAngle => r[:REFTOA], :Composition => read(db, Material, r[:REFERENCE]))
    kr = uv(r[:KRATIO], r[:DKRATIO])
    return DBKRatio(db, pkey, r[:CAMPAIGN], r[:SPECPKEY], primary, xrays, r[:MODE], meas, ref, kr)
end

function Base.findall(db::SQLite.DB, ::Type{DBKRatio}; material::Union{String,Nothing}=nothing, campaign::Union{Int,Nothing}=nothing, elm::Union{Element,Nothing}=nothing, mink::Float64=0.1)::Vector{DBKRatio}
    bs, args = "KRATIO >= ?", [ mink, ]
    if !isnothing(material)
        matkey = find(db, Material, material)
        @assert matkey!=-1 "Unable to find the material `$material`."
        bs *= " AND MEASURED = ?"
        push!(args, matkey)
    end
    if !isnothing(campaign)
        bs *= " AND CAMPAIGN = ?"
        push!(args, campaign)
    end
    if !isnothing(elm)
        bs *= " AND ELEMENT=?"
        push!(args, z(elm))
    end
    stmt = SQLite.Stmt(db, "SELECT PKEY FROM KRATIO WHERE $bs;")
    q = DBInterface.execute(stmt, args)
    return SQLite.done(q) ? [] : [read(db, DBKRatio, r[:PKEY]) for r in q]
end

function NeXLUncertainties.asa(
    ::Type{DataFrame}, #
    krs::AbstractVector{DBKRatio}; #
    withComputedKs::Bool = false, #
    mc::Type{<:MatrixCorrection} = XPP,
    fc::Type{<:FluorescenceCorrection} = ReedFluorescence,
    cc::Type{<:CoatingCorrection} = Coating
)
    fm, sm, cm = Union{Float64,Missing}, Union{String,Missing}, Union{Material,Missing}
    fs, xrays, mease0, meastoa, meascomp = Int[], Vector{CharXRay}[], Float64[], Float64[], cm[]
    refe0, reftoa, refcomp, krv, dkrv, cks, ratio = Float64[], Float64[], cm[], Float64[], Float64[], fm[], fm[]
    for kr in krs
        push!(fs, kr.campaign)
        push!(xrays, kr.xrays)
        meas = kr.measured
        push!(mease0, get(meas, :BeamEnergy, missing))
        push!(meastoa, get(meas, :TakeOffAngle, missing))
        push!(meascomp, get(meas, :Composition, missing))
        ref = kr.reference
        push!(refe0, get(ref, :BeamEnergy, missing))
        push!(reftoa, get(ref, :TakeOffAngle, missing))
        push!(refcomp, get(ref, :Composition, missing))
        push!(krv, value(kr.kratio))
        push!(dkrv, σ(kr.kratio))
        if withComputedKs
            elm = element(kr.xrays[1])
            if any(ismissing.((meascomp[end], mease0[end], meastoa[end], refcomp[end], refe0[end], reftoa[end]))) ||
               (NeXLCore.nonneg(meascomp[end], elm) < 1.0e-6) ||
               (NeXLCore.nonneg(refcomp[end], elm) < 1.0e-6) || (energy(inner(kr.primary))>0.95*min(mease0[end],refe0[end]))
                push!(cks, missing)
                push!(ratio, missing)
            else
                br = [ kr.primary ]
                zs = zafcorrection(mc, fc, cc, meascomp[end], br, mease0[end])
                zr = zafcorrection(mc, fc, cc, refcomp[end], br, refe0[end])
                k =
                    gZAFc(zs, zr, meastoa[end], reftoa[end] ) * NeXLCore.nonneg(meascomp[end], elm) /
                    NeXLCore.nonneg(refcomp[end], elm)
                push!(cks, k)
                push!(ratio, value(kr.kratio) / k)
            end
        end
    end
    res = DataFrame(
        Campaign = fs,
        Lines = xrays,
        Cmeas = meascomp,
        E0meas = mease0,
        TOAmeas = meastoa,
        Cref = refcomp,
        E0ref = refe0,
        TOAref = reftoa,
        K = krv,
        ΔK = dkrv,
    )
    if withComputedKs
        res[:, :Kxpp] = cks
        res[:, :Ratio] = ratio
    end
    return res
end

NeXLUncertainties.asa(::Type{KRatio}, dbkr::DBKRatio)::KRatio =
    KRatio(dbkr.xrays, dbkr.measured, dbkr.reference, dbkr.reference[:Composition], dbkr.kratio)

function Base.write(
    db::SQLite.DB,
    ::Type{DBKRatio},
    campaign::DBCampaign,
    meas::Spectrum,
    meascomp::Union{Material,Missing},
    res::FilterFitResult,
)
    stmt1 = SQLite.Stmt(
        db,
        "INSERT INTO KRATIO(CAMPAIGN, SPECPKEY, ELEMENT, INNER, OUTER, MODE, MEASURED, MEASNAME, MEASE0, MEASTOA, " *
        "REFERENCE, REFNAME, REFE0, REFTOA, PRINCIPAL, LINES, KRATIO, DKRATIO) VALUES (" *
        "?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);",
    )
    meascompidx = ismissing(meascomp) ? -1 : write(db, meascomp)
    measname = ismissing(meascomp) ? "Unknown" : name(meascomp)
    for lbl in filter(l -> (l isa CharXRayLabel) && (value(res[l]) > 0.0), labels(res))
        # @show lbl, value(res[lbl])
        ref, br = spectrum(lbl), brightest(lbl.xrays)
        refcomp = ref[:Composition]
        refcompidx = write(db, refcomp)
        r = DBInterface.execute(
            stmt1,
            (
                campaign.pkey, #
                meas[:PKEY],
                z(element(br)),
                inner(br).subshell.index,
                outer(br).subshell.index,
                "EDX", #
                meascompidx,
                measname,
                meas[:BeamEnergy],
                meas[:TakeOffAngle], #
                refcompidx,
                refcomp.name,
                ref[:BeamEnergy],
                ref[:TakeOffAngle], #
                repr(br),
                join(repr.(lbl.xrays), ","), #
                value(res[lbl]),
                uncertainty(res[lbl]),
            ),
        )
    end
end

"""
    NeXLMatrixCorrection.quantify(#
        krs::AbstractVector{DBKRatio};
        strip::AbstractVector{Element} = Element[],
        iteration::Iteration = Iteration(XPP, ReedFluorescence, Coating),
        kro::KRatioOptimizer = SimpleKRatioOptimizer(1.5),
    )::Vector{IterationResult}

Quantify a collection of `DBKRatio`.
"""
function NeXLMatrixCorrection.quantify(#
    krs::AbstractVector{DBKRatio};
    strip::AbstractVector{Element} = Element[],
    iteration::Iteration = Iteration(),
    kro::KRatioOptimizer = SimpleKRatioOptimizer(1.5),
)::Vector{IterationResult}
    map(unique(kr.spectrum for kr in krs)) do spec
        skrs = asa.(KRatio, filter(kr->kr.spectrum==spec, krs))
        okrs = optimizeks(kro, filter(kr -> !(element(kr) in strip), skrs))
        quantify(iteration, label("$spec"), okrs)
    end
end
