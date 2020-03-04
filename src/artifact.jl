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
    type::String
    format::String
    filename::String
    data
end

function Base.write(db::SQLite.DB, ::Type{DBArtifact}, filename::String, type::String, format::String)
    data = Mmap.mmap(filename, Vector{UInt8}, (stat(filename).size, ))
    stmt1 = SQLite.Stmt(db, "INSERT INTO ARTIFACT ( TYPE, FORMAT, FILENAME, DATA) VALUES ( ?, ?, ?, ? );")
    results = DBInterface.execute(stmt1, (type, format, filename, data))
    return  DBInterface.lastrowid(results)
end

function Base.read(db::SQLite, ::Type{DBArtifact}, pkey::Int)
    stmt1 = SQLite.Stmt(db, "SELECT (TYPE, FORMAT, FILENAME, DATA) FROM ARTIFACT WHERE PKEY=?;")
    q = DBInterface.execute(stmt1, (pkey, ))
    if SQLite.done(q)
        error("No artifact found with pkey=$(pkey)")
    end
    r=Row(q)
    return DBArtifact( r[:PKEY], r[:TYPE], r[:FORMAT], r[:FILENAME], r[:DATA] )
end
