using DataFrames

struct DBPerson
    pkey::Int
    name::String
    email::String
end

function Base.write(db::SQLite.DB, ::Type{DBPerson}, name::String, email::String)::Int
    stmt1 = SQLite.Stmt(db, "INSERT INTO PERSON ( NAME, EMAIL ) VALUES ( ?, ? );")
    r = DBInterface.execute(stmt1, ( name, email ))
    return DBInterface.lastrowid(r)
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

struct DBMember
    person::DBPerson
    laboratory::DBLaboratory
end

function Base.write(db::SQLite.DB, ::Type{DBMember}, labkey::Int, personkey::Int)::Int
    stmt1 = SQLite.Stmt(db, "INSERT INTO LABMEMBER ( LABKEY, PERSONKEY ) VALUES ( ?, ? );")
    r = DBInterface.execute(stmt1, ( labkey, personkey ))
    return DBInterface.lastrowid(r)
end

"""
    Base.findall(db::SQLite, ::Type{DBLaboratory}, person::DBPerson)::Vector{DBLaboratory}

Find all labs that the specified person is associated with.
"""
function Base.findall(db::SQLite, ::Type{DBLaboratory}, person::DBPerson)::Vector{DBLaboratory}
    stmt1 = SQLite.Stmt(db, "SELECT LABKEY, PERSONKEY FROM LABMEMBER WHERE PERSONKEY=?;")
    q = DBInterface.execute(stmt1, ( person.pkey, ))
    return [ read(db, DBLaboratory, r[:LABKEY]) for r in q ]
end

"""
    Base.findall(db::SQLite, ::Type{DBPerson}, lab::DBLaboratory)::Vector{DBPerson}

Find all people associated with the specified lab.
"""
function Base.findall(db::SQLite, ::Type{DBPerson}, lab::DBLaboratory)::Vector{DBPerson}
    stmt1 = SQLite.Stmt(db, "SELECT LABKEY, PERSONKEY FROM LABMEMBER WHERE LABKEY=?;")
    q = DBInterface.execute(stmt1, ( lab.pkey, ))
    return [ read(db, DBPerson, r[:PERSONKEY]) for r in q ]
end
