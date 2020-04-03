
struct DBKRatio
    pkey::Int
    fitspectra::Int
    primary::CharXRay
    lines::Vector{CharXRay}
    mode::Char
    standard::Dict{Symbol,Any}
    reference::Dict{Symbol,Any}
    kratio::UncertainValue
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
    stmt = SQLite.Stmt(db, "SELECT * FROM KRATIO WHERE FITSPEC=?;")
    q = DBInterface.execute(stmt, (fitspec,))
    return [read(db, DBKRatio, r[:PKEY]) for r in q]
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
