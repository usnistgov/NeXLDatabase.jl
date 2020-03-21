using DataFrames

struct DBPerson
    pkey::Int
    name::String
    email::String
end

Base.show(io::IO, per::DBPerson) = print(io, per.name)

function Base.write(db::SQLite.DB, ::Type{DBPerson}, name::String, email::String)::Int
    pk = find(db, DBPerson, email)
    if pk==-1
        stmt1 = SQLite.Stmt(db, "INSERT INTO PERSON ( NAME, EMAIL ) VALUES ( ?, ? );")
        r = DBInterface.execute(stmt1, ( name, email ))
        pk = DBInterface.lastrowid(r)
    end
    return pk
end

function Base.read(db::SQLite.DB, ::Type{DBPerson}, pkey::Int)::DBPerson
    stmt1 = SQLite.Stmt(db, "SELECT PKEY, NAME, EMAIL FROM PERSON WHERE PKEY=?;")
    q = DBInterface.execute(stmt1, ( pkey, ))
    if SQLite.done(q)
        error("No known person with key '$(pkey)'.")
    end
    r = SQLite.Row(q)
    return DBPerson(r[:PKEY], r[:NAME], r[:EMAIL])
end

function readPeople(db::SQLite.DB)::DataFrame
    stmt1 = SQLite.Stmt(db, "SELECT * FROM PERSON;")
    return DBInterface.execute(stmt1) |> DataFrame
end

function find(db::SQLite.DB, ::Type{DBPerson}, email::String)::Int
    stmt1 = SQLite.Stmt(db, "SELECT PKEY FROM PERSON WHERE EMAIL=?;")
    q = DBInterface.execute(stmt1, ( email, ))
    return SQLite.done(q) ? -1 : SQLite.Row(q)[:PKEY]
end
