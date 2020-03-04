

#CREATE TABLE SAMPLE (
#    PKEY INTEGER PRIMARY KEY AUTOINCREMENT,
#    OWNER INTEGER NOT NULL,
#    NAME TEXT NOT NULL, -- Ex: "Block C"
#    DESCRIPTION TEXT,
#    FOREIGN KEY(OWNER) REFERENCES LABORATORY(PKEY)
#);

struct DBSample
    pkey::Int
    owner::Int
    name::String
    description::String
end

function Base.write(db::SQLite.DB, ::Type{DBSample}, owner::DBLabratory, name::String, desc::String)
    data = Mmap.mmap(filename, Vector{UInt8}, (stat(filename).size, ))
    stmt1 = SQLite.Stmt(db, "INSERT INTO SAMPLE ( OWNER, NAME, DESCRIPTION ) VALUES ( ?, ?, ? );")
    results = DBInterface.execute(stmt1, (owner.pkey, name, desc ))
    return  DBInterface.lastrowid(results)
end

function Base.read(db::SQLite, ::Type{DBSample}, pkey::Int)
    stmt1 = SQLite.Stmt(db, "SELECT (TYPE, FORMAT, FILENAME, DATA) FROM ARTIFACT WHERE PKEY=?;")
    q = DBInterface.execute(stmt1, (pkey, ))
    if SQLite.done(q)
        error("No artifact found with pkey=$(pkey)")
    end
    r=Row(q)
    return DBSample( r[:PKEY], r[:TYPE], r[:FORMAT], r[:FILENAME], r[:DATA] )
end
