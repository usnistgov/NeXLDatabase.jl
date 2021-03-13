
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

function Base.findall(db::SQLite.DB, ::Type{DBInstrument}, lab::DBLaboratory; vendor=missing, model=missing)::Vector{DBInstrument}
    bs = "SELECT * FROM INSTRUMENT WHERE LABKEY=?"
    args = Any[ lab.pkey ]
    if !ismissing(vendor)
        bs *= " AND VENDOR=?"
        push!(args, vendor)
    end
    if !ismissing(model)
        bs *= " AND MODEL=?"
        push!(args, model)
    end
    stmt1 = SQLite.Stmt(db, bs*";")
    q = DBInterface.execute(stmt1, args)
    if SQLite.done(q)
        error("No known instruments for $args.")
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
    database::SQLite.DB
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

function NeXLUncertainties.asa(::Type{DataFrame}, det::DBDetector)::DataFrame
    prop, value = String[], String[]
    push!(prop,"Laboratory"), push!(value, det.instrument.laboratory.name)
    push!(prop,"Instrument"), push!(value, "$(det.instrument.vendor) $(det.instrument.model)")
    push!(prop,"Detector"), push!(value, "$(det.vendor) $(det.model): $(det.description)")
    push!(prop,"Resolution"), push!(value, "$(det.resolution) eV")
    push!(prop,"LLD"), push!(value, "$(det.lld) channels")
    push!(prop,"Energy"), push!(value, "$(det.zero) + $(det.gain)·i [eV]")
    sym(z) = elements[z].symbol
    push!(prop,"Visible"), push!(value, "K: Z>=$(sym(det.minK)), L: Z>=$(sym(det.minL)),  M: Z>=$(sym(det.minM)), N: Z>=$(sym(det.minN))")
    return DataFrame(Property=prop, Value=value)
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
        db,
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
    Dict{Shell,Element}(
        Shell(1) => elements[dbd.minK],
        Shell(2) => elements[dbd.minL], #
        Shell(3) => elements[dbd.minM],
        Shell(4) => elements[dbd.minN],
    ),
)

function Base.findall(db::SQLite.DB, ::Type{DBDetector}, inst::DBInstrument; vendor=missing, model=missing)::Vector{DBDetector}
    bs="SELECT PKEY FROM DETECTOR WHERE INSTRUMENT=?"
    args = Any[inst.pkey]
    if !ismissing(vendor)
        bs *= " AND VENDOR=?"
        push!(args,vendor)
    end
    if !ismissing(model)
        bs *= " AND MODEL=?"
        push!(args, model)
    end
    stmt1 = SQLite.Stmt(db, bs*";")
    q = DBInterface.execute(stmt1, args)
    return [ read(db, DBDetector, r[:PKEY]) for r in q ]
end

function find(db::SQLite.DB, ::Type{DBDetector}, inst::DBInstrument, desc::String)::Union{DBDetector, Missing}
    stmt1 = SQLite.Stmt(db, "SELECT PKEY FROM DETECTOR WHERE INSTRUMENT=? AND DESCRIPTION=?;")
    q = DBInterface.execute(stmt1, (inst.pkey, desc))
    return SQLite.done(q) ? missing : read(db, DBDetector, r[:PKEY])
end


function simpleEDS(dbd::DBDetector, channelcount::Int)
    return BasicEDS(channelcount, dbd.zero, dbd.gain, dbd.resolution, dbd.lld)
end