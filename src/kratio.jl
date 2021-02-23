using NeXLMatrixCorrection

struct DBKRatio
    pkey::Int
    fitspectra::Int
    spectrum::Int
    primary::CharXRay
    lines::Vector{CharXRay}
    mode::String
    measured::Dict{Symbol,Any}
    reference::Dict{Symbol,Any}
    kratio::UncertainValue
end

function Base.show(io::IO, kr::DBKRatio)
    print( io, "$(krname(kr)): $(kr.lines)] = $(kr.kratio)")
end

function krname(kr::DBKRatio)
    return "K[($(name(kr.measured[:Composition])) @ $(0.001*kr.measured[:BeamEnergy]) keV)/($(name(kr.reference[:Composition])) @ $(0.001*kr.reference[:BeamEnergy]) keV)"
end


function Base.read(db::SQLite.DB, ::Type{DBKRatio}, pkey::Int)::DBKRatio
    stmt = SQLite.Stmt(db, "SELECT * FROM KRATIO WHERE PKEY=?;")
    q = DBInterface.execute(stmt, (pkey,))
    SQLite.done(q) && error("There is no k-ratio with pkey = $(pkey).")
    r = SQLite.Row(q)
    primary = CharXRay(r[:ELEMENT], Transition(SubShell(r[:INNER]), SubShell(r[:OUTER])))
    lines = map(s -> parse(CharXRay, s), split(r[:LINES], ","))
    meas =
        Dict(:BeamEnergy => r[:MEASE0], :TakeOffAngle => r[:MEASTOA], :Composition => read(db, Material, r[:MEASURED]))
    ref = Dict(:BeamEnergy => r[:REFE0], :TakeOffAngle => r[:REFTOA], :Composition => read(db, Material, r[:REFERENCE]))
    kr = uv(r[:KRATIO], r[:DKRATIO])
    return DBKRatio(pkey, r[:FITSPEC], r[:SPECPKEY], primary, lines, r[:MODE], meas, ref, kr)
end

function Base.findall(db::SQLite.DB, ::Type{DBKRatio}; fitspec::Union{Int,Nothing}=nothing, elm::Union{Element,Nothing}=nothing, mink::Float64=0.1)::Vector{DBKRatio}
    bs, args = "KRATIO >= ?", [ mink, ]
    if !isnothing(fitspec)
        bs *= " AND FITSPEC = ?"
        push!(args,fitspec)
    end
    if !isnothing(elm)
        bs *= " AND ELEMENT=?"
        push!(args,z(elm))
    end
    stmt = SQLite.Stmt(db, "SELECT PKEY FROM KRATIO WHERE $bs;")
    q = DBInterface.execute(stmt, args)
    return SQLite.done(q) ? [] : [read(db, DBKRatio, r[:PKEY]) for r in q]
end

function NeXLUncertainties.asa(::Type{DataFrame}, krs::AbstractVector{DBKRatio}; withComputedKs::Bool = false)
    fm, sm, cm = Union{Float64,Missing}, Union{String,Missing}, Union{Material,Missing}
    fs, lines, mease0, meastoa, meascomp = Int[], String[], fm[], fm[], cm[]
    refe0, reftoa, refcomp, krv, dkrv, cks, ratio = fm[], fm[], cm[], Float64[], Float64[], fm[], fm[]
    for kr in krs
        push!(fs, kr.fitspectra)
        push!(lines, repr(kr.lines))
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
            elm = element(kr.lines[1])
            if any(ismissing.((meascomp[end], mease0[end], meastoa[end], refcomp[end], refe0[end], reftoa[end]))) ||
               (NeXLCore.nonneg(meascomp[end], elm) < 1.0e-6) ||
               (NeXLCore.nonneg(refcomp[end], elm) < 1.0e-6) || (energy(inner(kr.primary))>0.95*min(mease0[end],refe0[end]))
                push!(cks, missing)
                push!(ratio, missing)
            else
                br = [ kr.primary ]
                zs = zafcorrection(XPP, ReedFluorescence, Coating, meascomp[end], br, mease0[end])
                zr = zafcorrection(XPP, ReedFluorescence, Coating, refcomp[end], br, refe0[end])
                k =
                    gZAFc(zs, zr, meastoa[end], reftoa[end]) * NeXLCore.nonneg(meascomp[end], elm) /
                    NeXLCore.nonneg(refcomp[end], elm)
                push!(cks, k)
                push!(ratio, value(kr.kratio) / k)
            end
        end
    end
    res = DataFrame(
        Batch = fs,
        Lines = lines,
        E0meas = mease0,
        TOAmeas = meastoa,
        Cmeas = meascomp,
        E0ref = refe0,
        TOAref = reftoa,
        Cref = refcomp,
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
    KRatio(dbkr.lines, dbkr.measured, dbkr.reference, dbkr.reference[:Composition], dbkr.kratio)

function Base.write(
    db::SQLite.DB,
    ::Type{DBKRatio},
    fitspec::DBFitSpectra,
    meas::Spectrum,
    meascomp::Material,
    res::FilterFitResult,
)
    stmt1 = SQLite.Stmt(
        db,
        "INSERT INTO KRATIO(FITSPEC, SPECPKEY, ELEMENT, INNER, OUTER, MODE, MEASURED, MEASNAME, MEASE0, MEASTOA, " *
        "REFERENCE, REFNAME, REFE0, REFTOA, PRINCIPAL, LINES, KRATIO, DKRATIO) VALUES (" *
        "?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);",
    )
    meascompidx = write(db, meascomp)
    for lbl in filter(l -> (l isa CharXRayLabel) && (value(res[l]) > 0.0), labels(res))
        # @show lbl, value(res[lbl])
        ref, br = spectrum(lbl), brightest(lbl.xrays)
        refcomp = ref[:Composition]
        refcompidx = write(db, refcomp)
        r = DBInterface.execute(
            stmt1,
            (
                fitspec.pkey, #
                meas[:PKEY],
                z(element(br)),
                inner(br).subshell.index,
                outer(br).subshell.index,
                "EDX", #
                meascompidx,
                meascomp.name,
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

function NeXLMatrixCorrection.quantify( #
    dbkrs::AbstractVector{DBKRatio}, #
    strip::AbstractVector{Element}=Element[] #
)::Vector{IterationResult}
    map(unique(map(dbkr->dbkr.spectrum, dbkrs))) do spec
        krs = asa.(KRatio, filter(dbkr->dbkr.spectrum==spec && !(element(dbkr.primary) in strip), dbkrs))
        quantify("Unknown[$spec]", krs)
    end
end
