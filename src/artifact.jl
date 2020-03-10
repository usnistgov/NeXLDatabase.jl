using Mmap
using SQLite

#CREATE TABLE ARTIFACT (
#    PKEY INTEGER PRIMARY KEY AUTOINCREMENT,
#    FORMAT TEXT NOT NULL, -- EMSA, TIFF, PNG etc
#    FILENAME TEXT NOT NULL, -- Source filename
#    DATA BLOB NOT NULL
#);

struct DBArtifact
    pkey::Int
    format::String # EMSA, ASPEXTIFF, PNG, JPEG, ...
    filename::String
    data::Vector{UInt8}
end

function Base.write(db::SQLite.DB, ::Type{DBArtifact}, filename::String, format::String)::Int
    data = Mmap.mmap(filename, Vector{UInt8}, (stat(filename).size, ))
    stmt1 = SQLite.Stmt(db, "INSERT INTO ARTIFACT ( FORMAT, FILENAME, DATA) VALUES ( ?, ?, ? );")
    results = DBInterface.execute(stmt1, ( uppercase(format), filename, data ))
    return  DBInterface.lastrowid(results)
end

function Base.read(db::SQLite.DB, ::Type{DBArtifact}, pkey::Int)
    stmt1 = SQLite.Stmt(db, "SELECT * FROM ARTIFACT WHERE PKEY=?;")
    q = DBInterface.execute(stmt1, (pkey, ))
    if SQLite.done(q)
        error("No artifact found with pkey=$(pkey)")
    end
    r=SQLite.Row(q)
    return DBArtifact( r[:PKEY], r[:FORMAT], r[:FILENAME], r[:DATA] )
end

Base.read(db::SQLite.DB, ::Type{Spectrum}, pkey::Int)::Spectrum =
     convert(Spectrum, read(db,DBArtifact,pkey))

function Base.convert(::Type{Spectrum}, artifact::DBArtifact)::Spectrum
    if artifact.format=="EMSA"
        return readEMSA(IOBuffer(artifact.data), Float64)
    elseif artifact.format=="ASPEX"
        return readAspexTIFF(IOBuffer(artifact.data); withImgs=false)
    else
        error("Unexpected format $(art.format) for a spectrum file.")
    end
end
