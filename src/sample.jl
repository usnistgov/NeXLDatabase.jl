

#CREATE TABLE SAMPLE (
#    PKEY INTEGER PRIMARY KEY AUTOINCREMENT,
#    OWNER INTEGER NOT NULL,
#    NAME TEXT NOT NULL, -- Ex: "Block C"
#    DESCRIPTION TEXT,
#    FOREIGN KEY(OWNER) REFERENCES LABORATORY(PKEY)
#);

struct DBSample
    pkey::Int
    parent::Union{DBSample,Missing}
    owner::Int
    name::String
    description::String
end

function Base.write(db::SQLite.DB, ::Type{DBSample}, parentkey::Int, ownerkey::Int, name::String, desc::String)::Int
    stmt1 = SQLite.Stmt(db, "INSERT INTO SAMPLE ( PARENT, OWNER, NAME, DESCRIPTION ) VALUES (?, ?, ?, ? );")
    results = DBInterface.execute(stmt1, (parentkey, ownerkey, name, desc ))
    return  DBInterface.lastrowid(results)
end

Base.write(db::SQLite.DB, ::Type{DBSample}, ownerkey::Int, name::String, desc::String)::Int =
    write(db, DBSample, -1, ownerkey, name, desc)

Base.write(db::SQLite.DB, ::Type{DBSample}, parent::DBSample, owner::DBLaboratory, name::String, desc::String)::Int =
    write(db, DBSample, parent.pkey, owner.pkey, name, desc)

Base.write(db::SQLite.DB, ::Type{DBSample}, owner::DBLaboratory, name::String, desc::String)::Int =
    write(db, DBSample, owner.pkey, name, desc)

function Base.read(db::SQLite.DB, ::Type{DBSample}, pkey::Int)
    stmt1 = SQLite.Stmt(db, "SELECT * FROM SAMPLE WHERE PKEY=?;")
    q = DBInterface.execute(stmt1, (pkey, ))
    if SQLite.done(q)
        error("No sample found with pkey=$(pkey)")
    end
    r=SQLite.Row(q)
    parent = r[:PARENT] ≠ -1 ? read(db, DBSample, r[:PARENT]) : missing
    return DBSample( r[:PKEY], parent, r[:OWNER], r[:NAME], r[:DESCRIPTION])
end
