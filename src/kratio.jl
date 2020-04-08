using NeXLMatrixCorrection

struct DBKRatio
    pkey::Int
    fitspectra::Int
    primary::CharXRay
    lines::Vector{CharXRay}
    mode::String
    standard::Dict{Symbol,Any}
    reference::Dict{Symbol,Any}
    kratio::UncertainValue
end

function Base.show(io::IO, kr::DBKRatio)
    print(io, "K[($(name(kr.standard[:Composition])) @ $(kr.standard[:BeamEnergy]/1.0e3) keV)/"*
              "($(name(kr.reference[:Composition])) @ $(kr.reference[:BeamEnergy]/1.0e3) keV),"*
              "$(kr.lines)] = $(kr.kratio)")
end

function Base.read(db::SQLite.DB, ::Type{DBKRatio}, pkey::Int)::DBKRatio
    stmt = SQLite.Stmt(db, "SELECT * FROM KRATIO WHERE PKEY=?;")
    q = DBInterface.execute(stmt, (pkey,))
    SQLite.done(q) && error("There is no k-ratio with pkey = $(pkey).")
    r = SQLite.Row(q)
    primary = CharXRay(r[:ELEMENT], Transition(SubShell(r[:INNER]), SubShell(r[:OUTER])))
    lines = map(s -> parse(CharXRay, s), split(r[:LINES], ","))
    std = Dict(:BeamEnergy => r[:STDE0], :TakeOffAngle => r[:STDTOA], :Composition => read(db, Material, r[:STANDARD]))
    ref = Dict(:BeamEnergy => r[:REFE0], :TakeOffAngle => r[:REFTOA], :Composition => read(db, Material, r[:REFERENCE]))
    kr = uv(r[:KRATIO], r[:DKRATIO])
    return DBKRatio(pkey, r[:FITSPEC], primary, lines, r[:MODE], std, ref, kr)
end

function Base.findall(db::SQLite.DB, ::Type{DBKRatio}, fitspec::Int)::Vector{DBKRatio}
    stmt = SQLite.Stmt(db, "SELECT PKEY FROM KRATIO WHERE FITSPEC=?;")
    return [read(db, DBKRatio, r[:PKEY]) for r in DBInterface.execute(stmt, (fitspec,))]
end

function NeXLUncertainties.asa(::Type{DataFrame}, krs::AbstractVector{DBKRatio}; withComputedKs::Bool=false)
    fm, sm, cm = Union{Float64, Missing}, Union{String, Missing}, Union{Material, Missing}
    fs, lines, stde0, stdtoa, stdcomp = Int[], String[], fm[], fm[], cm[]
    refe0, reftoa, refcomp, krv, dkrv, cks, ratio = fm[], fm[], cm[], Float64[], Float64[], fm[], fm[]
    for kr in krs
        push!(fs, kr.fitspectra)
        push!(lines, repr(kr.lines))
        std = kr.standard
        push!(stde0, get(std,:BeamEnergy, missing))
        push!(stdtoa, get(std,:TakeOffAngle, missing))
        push!(stdcomp, get(std,:Composition, missing))
        ref = kr.reference
        push!(refe0, get(ref,:BeamEnergy, missing))
        push!(reftoa, get(ref,:TakeOffAngle, missing))
        push!(refcomp, get(ref,:Composition, missing))
        push!(krv, value(kr.kratio))
        push!(dkrv, σ(kr.kratio))
        if withComputedKs
            elm = element(kr.lines[1])
            if any(ismissing.( (stdcomp[end], stde0[end], stdtoa[end], refcomp[end], refe0[end], reftoa[end]) )) ||
                (NeXLCore.nonneg(stdcomp[end], elm)<1.0e-6) || (NeXLCore.nonneg(refcomp[end], elm)<1.0e-6)
                push!(cks, missing)
                push!(ratio, missing)
            else
                br = [ kr.primary ]
                zs = ZAF(XPP, ReedFluorescence, stdcomp[end], br, stde0[end])
            	zr = ZAF(XPP, ReedFluorescence, refcomp[end], br, refe0[end])
            	k = gZAFc(zs, zr, stdtoa[end], reftoa[end]) * NeXLCore.nonneg(stdcomp[end], elm) /
                    NeXLCore.nonneg(refcomp[end],elm)
                push!(cks, k)
                push!(ratio, value(kr.kratio) / k)
            end
        end
    end
    res = DataFrame(Batch=fs,Lines=lines,E0std=stde0,TOAstd=stdtoa,Cstd=stdcomp,E0ref=refe0, TOAref=reftoa, Cref=refcomp, K=krv, ΔK=dkrv)
    if withComputedKs
        insertcols!(res, ncol(res)+1, :Kxpp=>cks)
        insertcols!(res, ncol(res)+1, :Ratio=>ratio)
    end
    return res
end

function Base.findall(db::SQLite.DB, ::Type{DBKRatio}, filter::String, args::Tuple)::Vector{DBKRatio}
    stmt = SQLite.Stmt(db, "SELECT PKEY FROM KRATIO WHERE "*filter*";")
    return [read(db, DBKRatio, r[:PKEY]) for r in DBInterface.execute(stmt, args)]
end

function Base.write(
    db::SQLite.DB,
    ::Type{DBKRatio},
    fitspec::DBFitSpectra,
    std::Spectrum,
    stdcomp::Material,
    res::FilterFitResult,
)
    stmt1 = SQLite.Stmt(
        db,
        "INSERT INTO KRATIO(FITSPEC, ELEMENT, INNER, OUTER, MODE, STANDARD, STDNAME, STDE0, STDTOA, " *
        "REFERENCE, REFNAME, REFE0, REFTOA, PRINCIPAL, LINES, KRATIO, DKRATIO) VALUES (" *
        "?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);",
    )
    stdcompidx = write(db, stdcomp)
    for lbl in filter(l -> (l isa CharXRayLabel) && (value(res[l])>0.0), labels(res))
        ref, br = spectrum(lbl), brightest(lbl.xrays)
        refcomp = ref[:Composition]
        refcompidx = write(db, refcomp)
        r = DBInterface.execute(
            stmt1,
            (
                fitspec.pkey, #
                z(element(br)),
                inner(br).subshell.index,
                outer(br).subshell.index,
                "EDX", #
                stdcompidx,
                stdcomp.name,
                std[:BeamEnergy],
                std[:TakeOffAngle], #
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
