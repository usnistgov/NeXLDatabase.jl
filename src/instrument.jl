
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


function Base.write(db::SQLite.DB, ::Type{DBInstrument}, lab::DBLaboratory, vendor::String, model::String, location::String)::Int
    stmt1 = SQLite.Stmt(db, "INSERT INTO INSTRUMENT ( LABKEY, VENDOR, MODEL, LOCATION ) VALUES ( ?, ?, ?, ? );")
    r = DBInterface.execute(stmt1, ( lab.pkey, vendor, model, location ))
    return DBInterface.lastrowid(r)
end

function Base.read(db::SQLite.DB, ::Type{DBInstrument}, pkey::Int)::DBInstrument
    stmt1 = SQLite.Stmt(db, "SELECT * FROM INSTRUMENT WHERE PKEY=?;")
    q = DBInterface.execute(stmt1, ( pkey, ))
    if SQLite.done(q)
        error("No known person with key '$(pkey)'.")
    end
    r = SQLite.Row(q)
    return DBInstrument(r[:PKEY], read(db, DBLaboratory, r[:LABKEY]), r[:VENDOR], r[:MODEL], r[:LOCATION] )
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
end

function Base.write(db::SQLite.DB, ::Type{DBDetector}, inst::DBInstrument, vendor::String, model::String, desc::String)::DBDetector
    stmt1 = SQLite.Stmt(db, "INSERT INTO DETECTOR ( INSTRUMENT, VENDOR, MODEL, DESCRIPTION ) VALUES ( ?, ?, ?, ? );")
    r = DBInterface.execute(stmt1, ( inst.pkey, vendor, model, desc ))
    return read(db, DBDetector, convert(Int, DBInterface.lastrowid(r)))
end

function Base.read(db::SQLite.DB, ::Type{DBDetector}, pkey::Int)::DBDetector
    stmt1 = SQLite.Stmt(db, "SELECT * FROM DETECTOR WHERE PKEY=?;")
    q = DBInterface.execute(stmt1, ( pkey, ))
    if SQLite.done(q)
        error("No known detector with key '$(pkey)'.")
    end
    r = SQLite.Row(q)
    return DBDetector(r[:PKEY], read(db, DBInstrument, r[:INSTRUMENT]), r[:VENDOR], r[:MODEL], r[:DESCRIPTION] )
end
