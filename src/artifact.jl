using Mmap
using SQLite

#CREATE TABLE ARTIFACT (
#    PKEY INTEGER PRIMARY KEY AUTOINCREMENT,
#    TYPE TEXT NOT NULL, -- SPECTRUM, IMAGE, ...
#    FORMAT TEXT NOT NULL, -- EMSA, TIFF, PNG etc
#    FILENAME TEXT NOT NULL, -- Source filename
#    DATA BLOB NOT NULL
#);

struct DBArtifact
    pkey::Int
    type::String # SPECTRUM, IMAGE,
    format::String # ( EMSA, ASPEX ), (PNG, JPEG, ...)
    filename::String
    data
end

function Base.write(db::SQLite.DB, ::Type{DBArtifact}, filename::String, type::String, format::String)::Int
    data = Mmap.mmap(filename, Vector{UInt8}, (stat(filename).size, ))
    stmt1 = SQLite.Stmt(db, "INSERT INTO ARTIFACT ( TYPE, FORMAT, FILENAME, DATA) VALUES ( ?, ?, ?, ? );")
    results = DBInterface.execute(stmt1, (uppercase(type), uppercase(format), filename, data))
    return  DBInterface.lastrowid(results)
end

function Base.read(db::SQLite.DB, ::Type{DBArtifact}, pkey::Int)
    stmt1 = SQLite.Stmt(db, "SELECT * FROM ARTIFACT WHERE PKEY=?;")
    q = DBInterface.execute(stmt1, (pkey, ))
    if SQLite.done(q)
        error("No artifact found with pkey=$(pkey)")
    end
    r=SQLite.Row(q)
    return DBArtifact( r[:PKEY], r[:TYPE], r[:FORMAT], r[:FILENAME], r[:DATA] )
end

Base.read(db::SQLite.DB, ::Type{Spectrum}, pkey::Int)::Spectrum =
     convert(Spectrum, read(db,DBArtifact,pkey))

function Base.convert(::Type{Spectrum}, artifact::DBArtifact)::Spectrum
    if artifact.type!="SPECTRUM"
        error("This artifact is not a spectrum.")
    end
    if artifact.format=="EMSA"
        return readEMSA(IOBuffer(art.data), Float64)
    elseif artifact.format=="ASPEX"
        return readAspexTIFF(IOBuffer(art.data); withImgs=true)
    else
        error("Unknown spectrum format $(art.format).")
    end
end
