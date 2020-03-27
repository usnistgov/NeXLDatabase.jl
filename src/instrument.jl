
struct DBInstrument
    pkey::Int
    laboratory::DBLaboratory
    vendor::String
    model::String
    location::String
end

#CREATE TABLE INSTRUMENT (
#    PKEY INTEGER PRIMARY KEY AUTOINCREMENT,
#    LABKEY INTEGER NOT NULL,
#    VENDOR TEXT NOT NULL,
#    MODEL TEXT NOT NULL,
#    LOCATION TEXT NOT NULL,
#    FOREIGN KEY(LABKEY) REFERENCES LABORATORY(PKEY)
#);

Base.show(io::IO, inst::DBInstrument) = print(io, "$(inst.laboratory)'s $(inst.vendor) $(inst.model)")

function Base.write(
    db::SQLite.DB,
    ::Type{DBInstrument},
    labkey::Int,
    vendor::String,
    model::String,
    location::String,
)::Int
    stmt1 = SQLite.Stmt(db, "INSERT INTO INSTRUMENT ( LABKEY, VENDOR, MODEL, LOCATION ) VALUES ( ?, ?, ?, ? );")
    r = DBInterface.execute(stmt1, (labkey, vendor, model, location))
    return DBInterface.lastrowid(r)
end

Base.write(
    db::SQLite.DB,
    ::Type{DBInstrument},
    lab::DBLaboratory,
    vendor::String,
    model::String,
    location::String,
)::Int = write(db, DBInstrument, lab.pkey, vendor, model, location)

function Base.read(db::SQLite.DB, ::Type{DBInstrument}, pkey::Int)::DBInstrument
    stmt1 = SQLite.Stmt(db, "SELECT * FROM INSTRUMENT WHERE PKEY=?;")
    q = DBInterface.execute(stmt1, (pkey,))
    if SQLite.done(q)
        error("No known instrument with key '$(pkey)'.")
    end
    r = SQLite.Row(q)
    return DBInstrument(r[:PKEY], read(db, DBLaboratory, r[:LABKEY]), r[:VENDOR], r[:MODEL], r[:LOCATION])
end

function Base.findall(db::SQLite.DB, ::Type{DBInstrument}, lab::DBLaboratory)::Vector{DBInstrument}
    stmt1 = SQLite.Stmt(db, "SELECT * FROM INSTRUMENT WHERE LABKEY=?;")
    q = DBInterface.execute(stmt1, (lab.pkey,))
    if SQLite.done(q)
        error("No known instruments for the laboratory '$(lab)'.")
    end
    return [ DBInstrument(r[:PKEY], lab, r[:VENDOR], r[:MODEL], r[:LOCATION]) for r in q ]
end


#CREATE TABLE DETECTOR (
#    PKEY INTEGER PRIMARY KEY AUTOINCREMENT,
#    INSTRUMENT INTEGER NOT NULL,
#    VENDOR TEXT NOT NULL,
#    MODEL TEXT NOT NULL,
#    DESCRIPTION TEXT,
#    FOREIGN KEY(INSTRUMENT) REFERENCES INSTRUMENT(PKEY)
#);

struct DBDetector
    pkey::Int
    instrument::DBInstrument
    vendor::String
    model::String
    description::String
    resolution::Float64
    lld::Int
    zero::Float64
    gain::Float64
    minK::Int
    minL::Int
    minM::Int
    minN::Int
end

Base.show(io::IO, det::DBDetector) = print(io, "$(det.vendor) $(det.model) $(det.description) on $(repr(det.instrument))")

function Base.write(
    db::SQLite.DB,
    ::Type{DBDetector}, #
    instkey::Int,
    vendor::String,
    model::String,
    desc::String, #
    fwhm::Float64,
    lld::Int,
    zero::Float64,
    gain::Float64, #
    minK::Int,
    minL::Int,
    minM::Int,
    minN::Int, #
)::Int
    stmt1 = SQLite.Stmt(
        db,
        "INSERT INTO DETECTOR ( INSTRUMENT, VENDOR, MODEL, DESCRIPTION, RESOLUTION, LLD, ZERO, GAIN, MINK, MINL, MINM, MINN ) VALUES ( ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ? );",
    )
    r = DBInterface.execute(stmt1, (instkey, vendor, model, desc, fwhm, lld, zero, gain, minK, minL, minM, minN))
    return convert(Int, DBInterface.lastrowid(r))
end

Base.write(
    db::SQLite.DB,
    ::Type{DBDetector}, #
    inst::DBInstrument,
    vendor::String,
    model::String,
    desc::String, #
    fwhm::Float64,
    lld::Int,
    zero::Float64,
    gain::Float64, #
    minK::Int,
    minL::Int,
    minM::Int,
    minN::Int, #
)::Int = write(db, DBDetector, inst.pkey, vendor, model, desc, fwhm, lld, zero, gain, minK, minL, minM, minN)

function Base.read(db::SQLite.DB, ::Type{DBDetector}, pkey::Int)::DBDetector
    stmt1 = SQLite.Stmt(db, "SELECT * FROM DETECTOR WHERE PKEY=?;")
    q = DBInterface.execute(stmt1, (pkey,))
    if SQLite.done(q)
        error("No known detector with key '$(pkey)'.")
    end
    r = SQLite.Row(q)
    return DBDetector(
        r[:PKEY],
        read(
            db,
            DBInstrument, #
            r[:INSTRUMENT],
        ),
        r[:VENDOR],
        r[:MODEL],
        r[:DESCRIPTION], #
        r[:RESOLUTION],
        r[:LLD],
        r[:ZERO],
        r[:GAIN], #
        r[:MINK],
        r[:MINL],
        r[:MINM],
        r[:MINN],
    )
end

Base.convert(::Type{BasicEDS}, dbd::DBDetector, chCount::Int = 4096) = BasicEDS(
    chCount,
    dbd.zero,
    dbd.gain,
    dbd.resolution,
    dbd.lld, #
    Dict{Char,Element}(
        'K' => elements[dbd.minK],
        'L' => elements[dbd.minL], #
        'M' => elements[dbd.minM],
        'N' => elements[dbd.minN],
    ),
)

function Base.findall(db::SQLite.DB, ::Type{DBDetector}, inst::DBInstrument)::Vector{DBDetector}
    stmt1 = SQLite.Stmt(db, "SELECT PKEY FROM DETECTOR WHERE INSTRUMENT=?;")
    q = DBInterface.execute(stmt1, (inst.pkey,))
    return [ read(db, DBDetector, r[:PKEY]) for r in q ]
end
