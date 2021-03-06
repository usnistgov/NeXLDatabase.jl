
struct DBSample
    database::SQLite.DB
    pkey::Int
    parent::Union{DBSample,Missing}
    owner::DBLaboratory
    name::String
    description::String
end

function Base.show(io::IO, samp::DBSample)
    helper(samp) = (ismissing(samp.parent) ? samp.name : helper(samp.parent)*" : "*samp.name)
    print(io, "$(samp.owner)'s $(helper(samp))")
end

function Base.write(db::SQLite.DB, ::Type{DBSample}, parentkey::Int, ownerkey::Int, name::String, desc::String)::Int
    stmt1 = SQLite.Stmt(db, "INSERT INTO SAMPLE ( PARENT, OWNER, NAME, DESCRIPTION ) VALUES (?, ?, ?, ? );")
    results = DBInterface.execute(stmt1, (parentkey, ownerkey, name, desc ))
    return  DBInterface.lastrowid(results)
end

function Base.findall(db::SQLite.DB, ::Type{DBSample}, owner::DBLaboratory; parent=missing, name=missing, desc=missing)
    bs = "SELECT PKEY FROM SAMPLE WHERE OWNER=?"
    args = Any[ owner.pkey ]
    if !ismissing(parent)
        bs *= " AND PARENT=?"
        push!(args, parent)
    end
    if !ismissing(name)
        bs *= " AND NAME=?"
        push!(args, name)
    end
    if !ismissing(desc)
        bs *= " AND DESCRIPTION=?"
        push!(args, desc)
    end
    stmt = SQLite.Stmt(db,bs*";")
    q = DBInterface.execute(stmt, args)
    return [ read(db, DBSample, r[:PKEY]) for r in q ]
end

function find(db::SQLite.DB, ::Type{DBSample}, owner::Int)::Vector{DBSample}
    stmt = SQLite.Stmt(db,"SELECT PKEY FROM SAMPLE WHERE OWNER=?;")
    q = DBInterface.execute(stmt, (owner,))
    return [ read(db, DBSample, r[:PKEY]) for r in q ]
end

function find(db::SQLite.DB, ::Type{DBSample}, owner::Int, parent::Int)::Vector{DBSample}
    stmt = SQLite.Stmt(db,"SELECT PKEY FROM SAMPLE WHERE OWNER=? AND PARENT=?;")
    q = DBInterface.execute(stmt, (owner,parent))
    return [ read(db, DBSample, r[:PKEY]) for r in q ]
end

function find(db::SQLite.DB, ::Type{DBSample}, owner::DBLaboratory, name::String)::Union{DBSample,Nothing}
    stmt = SQLite.Stmt(db,"SELECT PKEY FROM SAMPLE WHERE OWNER=? AND NAME=?;")
    q = DBInterface.execute(stmt, (owner.pkey, name))
    return SQLite.done(q) ? nothing : read(db, DBSample, SQLite.Row(q)[:PKEY])
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
    owner = read(db, DBLaboratory, r[:OWNER])
    return DBSample(db, r[:PKEY], parent, owner, r[:NAME], r[:DESCRIPTION])
end
