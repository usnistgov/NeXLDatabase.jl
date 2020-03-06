
struct DBLaboratory
    pkey::Int
    name::String
    contact::DBPerson
end

function Base.write(db::SQLite.DB, ::Type{DBLaboratory}, name, contact::DBPerson)::DBLaboratory
    stmt1 = SQLite.Stmt(db, "INSERT INTO LABORATORY ( NAME, CONTACT ) VALUES ( ?, ? );")
    r = DBInterface.execute(stmt1, ( name, contact.pkey))
    return read(db, DBLaboratory, convert(Int,DBInterface.lastrowid(r)))
end

function Base.read(db::SQLite.DB, ::Type{DBLaboratory}, pkey::Int)::DBLaboratory
    stmt1 = SQLite.Stmt(db, "SELECT * FROM LABORATORY WHERE PKEY=?;")
    q = DBInterface.execute(stmt1, ( pkey, ))
    if SQLite.done(q)
        error("No known laboratory with key '$(pkey)'.")
    end
    r = SQLite.Row(q)
    contact = read(db, DBPerson, r[:CONTACT])
    return DBLaboratory(r[:PKEY], r[:NAME], contact)
end

function readLaboratories(db::SQLite.DB)::DataFrame
    stmt1 = SQLite.Stmt(db, "SELECT * FROM LABORATORY;")
    return DBInterface.execute(stmt1) |> DataFrame
end
