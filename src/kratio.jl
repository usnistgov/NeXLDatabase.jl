
struct DBKRatio
    pkey::Int
    fitspectra::Int
    primary::CharXRay
    lines::Vector{CharXRay}
    mode::Char
    unknown::Dict{Symbol,Any}
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
    unk = Dict(:BeamEnergy => r[:UNKE0], :TakeOffAngle => r[:UNKTOA], :Composition => read(db, Material, r[:UNKNOWN]))
    ref = Dict(:BeamEnergy => r[:REFE0], :TakeOffAngle => r[:REFTOA], :Composition => read(db, Material, r[:REFERENCE]))
    kr = uv(r[:KRATIO], r[:DKRATIO])
    return DBKRatio(pkey, r[:FITSPEC], primary, lines, r[:MODE], unk, ref, kr)
end

function Base.findall(db::SQLite.DB, ::Type{DBKRatio}, fitspec::Int)::Vector{DBKRatio}
    stmt = SQLite.Stmt(db, "SELECT * FROM KRATIO WHERE FITSPEC=?;")
    q = DBInterface.execute(stmt, (fitspec,))
    return [read(db, DBKRatio, r[:PKEY]) for r in q]
end

function Base.write(
    db::SQLite.DB,
    ::Type{DBKratio},
    fitspec::DBFitSpectra,
    unk::Spectrum,
    unkcomp::Material,
    res::FilterFitResult,
)
    stmt1 = SQLite.Stmt(
        db,
        "INSERT INTO KRATIO(FITSPEC, ELEMENT, INNER, OUTER, MODE, UNKNOWN, UNKE0, UNKTOA, " *
        "REFERENCE, REFE0, REFTOA, PRINCIPAL, LINES, KRATIO, DKRATIO) VALUES (" *
        "?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);",
    )
    unkcompidx = write(db, unkcomp)
    for lbl in filter(l -> l isa CharXRayLabel, labels(res))
        ref, br = spectrum(lbl), brightest(lbl.xrays)
        refcompidx = write(db, ref[:Composition])
        r = DBInterface.execute(
            stmt,
            ( #
                fitspec.pkey, #
                z(element(br)),
                inner(br),
                outer(br),
                'E', #
                unkcompidx,
                unkspec[:BeamEnergy],
                unkspec[:TakeOffAngle], #
                refcompidx,
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
