using DataFrames

struct DBPerson
    pkey::Int
    name::String
    email::String
end

Base.show(io::IO, per::DBPerson) = print(io, per.name)

function NeXLUncertainties.asa(::Type{DataFrame}, people::AbstractArray{DBPerson})
    return DataFrame(
        PKey = [ person.pkey for person in people ],
        Name = [ person.name for person in people ],
        EMail = [ person.email for person in people ]
    )
end

function Base.write(db::SQLite.DB, ::Type{DBPerson}, name::String, email::String)::Int
    (find(db, DBPerson, email) == -1) || error("A person with e-mail address $email already exists.")
    stmt1 = SQLite.Stmt(db, "INSERT INTO PERSON ( NAME, EMAIL ) VALUES ( ?, ? );")
    q = DBInterface.execute(stmt1, ( name, lowercase(email) ))
    return DBInterface.lastrowid(q)
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

function Base.findall(db::SQLite.DB, ::Type{DBPerson})::Vector{DBPerson}
    stmt1 = SQLite.Stmt(db, "SELECT PKEY FROM PERSON;")
    q = DBInterface.execute(stmt1)
    return [ read(db, DBPerson, r[:PKEY]) for r in q]
end

function find(db::SQLite.DB, ::Type{DBPerson}, email::String)::Int
    stmt1 = SQLite.Stmt(db, "SELECT PKEY FROM PERSON WHERE EMAIL=?;")
    q = DBInterface.execute(stmt1, ( lowercase(email), ))
    return SQLite.done(q) ? -1 : SQLite.Row(q)[:PKEY]
end

function Base.read(db::SQLite.DB, ::Type{DBPerson}, email::String)::DBPerson
    stmt1 = SQLite.Stmt(db, "SELECT PKEY, NAME, EMAIL FROM PERSON WHERE EMAIL=?;")
    q = DBInterface.execute(stmt1, ( email, ))
    if SQLite.done(q)
        error("No known person with e-mail '$(email)'.")
    end
    r = SQLite.Row(q)
    return DBPerson(r[:PKEY], r[:NAME], r[:EMAIL])
end
