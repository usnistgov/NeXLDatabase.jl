
struct DBLaboratory
    pkey::Int
    name::String
    contact::DBPerson
end

function Base.write(db::SQLite.DB, ::Type{DBLaboratory}, name, contactkey::Int)::Int
    stmt1 = SQLite.Stmt(db, "INSERT INTO LABORATORY ( NAME, CONTACT ) VALUES ( ?, ? );")
    r = DBInterface.execute(stmt1, ( name, contactkey))
    res = DBInterface.lastrowid(r)
    write(db, DBMember, Int(res), contactkey)
    return res
end

Base.write(db::SQLite.DB, ::Type{DBLaboratory}, name, contact::DBPerson)::Int =
    write(db, DBLaboratory, name, contact.pkey)

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

struct DBMember
    person::DBPerson
    laboratory::DBLaboratory
end

function Base.write(db::SQLite.DB, ::Type{DBMember}, labkey::Int, personkey::Int)::Int
    stmt1 = SQLite.Stmt(db, "INSERT INTO LABMEMBER ( LABKEY, PERSONKEY ) VALUES ( ?, ? );")
    r = DBInterface.execute(stmt1, ( labkey, personkey ))
    return DBInterface.lastrowid(r)
end

Base.write(db::SQLite.DB, ::Type{DBMember}, lab::DBLaboratory, person::DBPerson)::Int =
    write(db, DBMember, lab.pkey, person.pkey)

"""
    Base.findall(db::SQLite, ::Type{DBLaboratory}, person::DBPerson)::Vector{DBLaboratory}

Find all labs that the specified person is associated with.
"""
function Base.findall(db::SQLite.DB, ::Type{DBLaboratory}, person::DBPerson)::Vector{DBLaboratory}
    stmt1 = SQLite.Stmt(db, "SELECT LABKEY, PERSONKEY FROM LABMEMBER WHERE PERSONKEY=?;")
    q = DBInterface.execute(stmt1, ( person.pkey, ))
    return [ read(db, DBLaboratory, r[:LABKEY]) for r in q ]
end

"""
    Base.findall(db::SQLite, ::Type{DBPerson}, lab::DBLaboratory)::Vector{DBPerson}

Find all people associated with the specified lab.
"""
function Base.findall(db::SQLite.DB, ::Type{DBPerson}, lab::DBLaboratory)::Vector{DBPerson}
    stmt1 = SQLite.Stmt(db, "SELECT LABKEY, PERSONKEY FROM LABMEMBER WHERE LABKEY=?;")
    q = DBInterface.execute(stmt1, ( lab.pkey, ))
    return [ read(db, DBPerson, r[:PERSONKEY]) for r in q ]
end
