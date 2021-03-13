"""
What element(s) is this material suitable as a standard for?
"""
struct DBStandardFor
    database::SQLite.DB
    element::Element
    material::Material
end

function Base.write(db::SQLite.DB, ::Type{DBStandardFor}, elm::Element, mat::Union{String, Material, Integer})
    if mat isa String
        matkey = find(db, Material, mat)
        mat = read(db, Material, matkey)
    elseif mat isa Material
        matkey = write(db, mat)
    else
        matkey = mat
        mat = read(db, Material, matkey)
    end
    @assert haskey(mat, elm) "The material $mat does not contain the element $elm."
    stmt1 = SQLite.Stmt(db, "SELECT * FROM STANDARDFOR WHERE ELEMENT=? AND MATKEY=?;")
    q1 = DBInterface.execute(stmt1, ( z(elm), matkey, ) )
    if SQLite.done(q1)
        stmt1 = SQLite.Stmt(db, "INSERT INTO STANDARDFOR ( ELEMENT, MATKEY ) VALUES ( ?, ? );")
        DBInterface.execute(stmt1, ( z(elm), matkey, ) )
    end
    return lastrowid(q1)
end

function Base.findall(db::SQLite.DB, ::Type{DBStandardFor}, elm::Element)::Array{DBMaterial}
    stmt1 = SQLite.Stmt(db, "SELECT * FROM STANDARDFOR WHERE ELEMENT=?;")
    q1 = DBInterface.execute(stmt1, ( z(elm), ) )
    return [ read(db, r[:MATKEY]) for r in q1 ]
end
