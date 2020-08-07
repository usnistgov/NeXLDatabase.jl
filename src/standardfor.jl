
"""
What element(s) is this material suitable as a standard for?
"""
struct DBStandardFor
    element::Element
    material::Material
end

function Base.write(db::SQLite.DB, ::Type{DBStandardFor}, elm::Element, mat::Union{Material,Integer})
    matkey = mat isa Material ? write(db, Material) : mat
    stmt1 = SQLite.Stmt(db, "SELECT * FROM STANDARDFOR WHERE ELEMENT=? AND MATERIAL=?;")
    q1 = DBInterface.execute(stmt1, ( z(elm), matkey, ) )
    if SQLite.done(q1)
        stmt1 = SQLite.Stmt(db, "INSERT INTO STANDARDFOR ( ELEMENT, MATKEY ) VALUES ( ?, ? );")
        DBInterface.execute(stmt1, ( z(elm), matkey, ) )
    end
    return DBStandardFor(elm, mat)
end

function Base.findall(db::SQLite.DB, ::Type{DBStandardFor}, elm::Element)::Array{DBMaterial}
    stmt1 = SQLite.Stmt(db, "SELECT * FROM STANDARDFOR WHERE ELEMENT=?;")
    q1 = DBInterface.execute(stmt1, ( z(elm), ) )
    return [ read(db, r[:MATKEY]) for r in q1 ]
end
