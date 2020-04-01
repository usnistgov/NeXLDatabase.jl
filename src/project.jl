using Dates

struct DBProject
    pkey::Int
    parent::Union{DBProject,Missing}
    createdBy::DBPerson
    name::String
    description::String
end

Base.show(io::IO, pr::DBProject) =
    print(io, (!ismissing(pr.parent) ? repr(pr.parent)*" : " : "")*pr.name)

Base.write(db::SQLite.DB, ::Type{DBProject}, name::String, desc::String, createdBy::DBPerson)::Int =
    write(db, DBProject, name, desc, createdBy.pkey, 0)

Base.write(db::SQLite.DB, ::Type{DBProject}, name::String, desc::String, createdBy::DBPerson, parent::DBProject)::Int =
    write(db, DBProject, name, desc, createdBy.pkey, parent.pkey)

function Base.write(db::SQLite.DB, ::Type{DBProject}, name::String, desc::String, personKey::Int, parentkey::Int)::Int
    stmt1 = SQLite.Stmt(db, "INSERT INTO PROJECT ( PARENT, CREATEDBY, NAME, DESCRIPTION ) VALUES ( ?, ?, ?, ? );")
    r = DBInterface.execute(stmt1, ( parentkey, personKey, name, desc ))
    return DBInterface.lastrowid(r)
end

function Base.read(db::SQLite.DB, ::Type{DBProject}, pkey::Int)::DBProject
    stmt1 = SQLite.Stmt(db, "SELECT * FROM PROJECT WHERE PKEY=?;")
    q = DBInterface.execute(stmt1, ( pkey, ))
    if SQLite.done(q)
        error("No known project with key '$(pkey)'.")
    end
    r = SQLite.Row(q)
    # Recursively read parent projects
    parent = r[:PARENT] < 0 ? missing : read(db, DBProject, r[:PARENT])
    return DBProject(r[:PKEY], parent, read(db, DBPerson, r[:CREATEDBY]), r[:NAME], r[:DESCRIPTION])
end

function Base.findall(db::SQLite.DB, ::Type{DBProject}, parent::DBProject)::Vector{DBProject}
    stmt1 = SQLite.Stmt(db, "SELECT * FROM PROJECT WHERE PARENT=?;")
    q = DBInterface.execute(stmt1, ( parent.pkey, ))
    return [ DBProject(r[:PKEY], parent, read(db, DBPerson, r[:CREATEDBY]), r[:NAME], r[:DESCRIPTION]) for r in q]
end

Base.findall(db::SQLite.DB, ::Type{DBProject}, parentkey::Int)::Vector{DBProject} =
    findall(db, DBProject, read(db, DBProject, parentkey))

function find(db::SQLite.DB, ::Type{DBProject}, parentkey::Int, name::String)::Int
    stmt1 = SQLite.Stmt(db, "SELECT PKEY FROM PROJECT WHERE PARENT=? AND NAME=?;")
    q = DBInterface.execute(stmt1, ( parentkey, name))
    return SQLite.done(q) ? -1 : SQLite.Row(q)[:PKEY]
end

function Base.read(db::SQLite.DB, ::Type{DBProject}, parentkey::Int, name::String)::DBProject
    stmt1 = SQLite.Stmt(db, "SELECT * FROM PROJECT WHERE PARENT=? AND NAME=?;")
    q = DBInterface.execute(stmt1, ( parentkey, name))
    if SQLite.done(q)
        error("No known project with $name.")
    end
    r = SQLite.Row(q)
    parent = r[:PARENT] >= 0 ? read(db, DBProject, r[:PARENT]) : missing
    return DBProject(r[:PKEY], parent, read(db, DBPerson, r[:CREATEDBY]), r[:NAME], r[:DESCRIPTION])
end

function Base.findall(db::SQLite.DB, ::Type{DBProject}, createdby::DBPerson)::Vector{DBProject}
    stmt1 = SQLite.Stmt(db, "SELECT PKEY FROM PROJECT WHERE CREATEDBY=?;")
    q = DBInterface.execute(stmt1, ( createdby.pkey, ))
    return [ read(db, DBProject, r[:PKEY]) for r in q]
end
