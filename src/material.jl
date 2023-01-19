export has

using IntervalSets

function Base.write(db::SQLite.DB, ::Type{Material}, mat::Material; atol=1.0e-4)::Int
    res = find(db, Material, mat.name)
    if res ≠ -1
        dbmat = read(db, Material, res)
        if !isapprox(mat, dbmat, atol=atol)
            error("$(mat.name) has already been defined as $(mat).")
        end
    else
        stmt1 = SQLite.Stmt(db, "INSERT INTO MATERIAL (MATNAME, MATDESCRIPTION, MATDENSITY, MATPEDIGREE) VALUES ( ?, ?, ?, ? );")
        r = DBInterface.execute(stmt1, (name(mat), get(mat, :Description, ""), get(mat, :Density, missing), get(mat, :Pedigree, missing)))
        res = DBInterface.lastrowid(r)
        stmt2 = SQLite.Stmt(db, "SELECT PKEY FROM MATERIAL WHERE MATNAME=?;")
        pkey = (DBInterface.execute(stmt2, (name(mat), )) |> DataFrame)[end,:PKEY]
        stmt3 = SQLite.Stmt(db, "INSERT INTO MASSFRACTION ( MATKEY, MFZ, MFC, MFUC, MFA ) VALUES ( ?, ?, ?, ?, ? )")
        foreach(elm->DBInterface.execute(stmt3, (pkey, z(elm), value(mat[elm]), σ(mat[elm]), get(mat.a, elm, 0.0))), keys(mat))
    end
    return res
end

Base.write(db::SQLite.DB, mat::Material; atol=1.0e-4) = write(db, Material, mat, atol=atol)

function Base.read(db::SQLite.DB, ::Type{Material}, pkey::Int)::Material
    stmt1 = SQLite.Stmt(db, "SELECT * FROM MATERIAL WHERE PKEY=?;")
    q1 = DBInterface.execute(stmt1, (pkey, ))
    if SQLite.done(q1)
        error("No known material with pkey = '$(pkey)'.")
    end
    r1 = SQLite.Row(q1)
    row, den, desc = r1[:PKEY], r1[:MATDENSITY], r1[:MATDESCRIPTION]
    stmt2 = SQLite.Stmt(db, "SELECT * FROM MASSFRACTION WHERE MATKEY=?;")
    q2 = DBInterface.execute(stmt2, (row, ))
    massfrac, aa = Dict{Element,UncertainValue}(), Dict{Element,Float64}()
    for r2 in q2
        @assert r2[:MATKEY]==row
        z, c, uc, a = elements[r2[:MFZ]], r2[:MFC], r2[:MFUC], r2[:MFA]
        massfrac[z] = uv(c,uc)
        a>0.0 && (aa[z]=a)
    end
    props=Dict{Symbol,Any}()
    if !ismissing(den)
        props[:Density]=den
    end
    if (!ismissing(desc)) && (lastindex(desc)>=1)
        props[:Description]=desc
    end
    mat = Material(r1[:MATNAME], massfrac, aa, props)
    mat[:Database] = db
    return mat
end

function find(db::SQLite.DB, ::Type{Material}, matname::AbstractString)::Int
    stmt1 = SQLite.Stmt(db, "SELECT PKEY FROM MATERIAL WHERE MATNAME=?;")
    q1 = DBInterface.execute(stmt1, (matname, ))
    return SQLite.done(q1) ? -1 : SQLite.Row(q1)[:PKEY]
end

NeXLCore.has(db::SQLite.DB, ::Type{Material}, matname::AbstractString)::Bool =
    find(db, Material, matname) ≠ -1

Base.read(db::SQLite.DB, ::Type{Material}, matname::AbstractString)::Material =
    read(db, Material, find(db, Material, matname))

function NeXLCore.material(db::SQLite.DB, matname::AbstractString)
    idx = find(db, Material, matname)
    if idx ≠ -1
        return read(db, Material, idx)
    else
        error("Unable to find $(matname) in the material database.")
    end
end

function Base.delete!(db::SQLite.DB, ::Type{Material}, matname::AbstractString)
    stmt1 = SQLite.Stmt(db, "SELECT PKEY, * FROM MATERIAL WHERE MATNAME=?;")
    q1 = DBInterface.execute(stmt1, (matname, ))
    for r1 in q1
        SQLite.transaction(db) do
            stmt1 = SQLite.Stmt(db, "DELETE FROM MASSFRACTION where MATKEY=?;")
            DBInterface.execute(stmt1, (r1[:PKEY], ))
            stmt2 = SQLite.Stmt(db, "DELETE FROM MATERIAL where PKEY=?;")
            DBInterface.execute(stmt2, (r1[:PKEY], ))
        end
    end
end

Base.filter(db::SQLite.DB, ::Type{Material}, prs::Pair{Element, ClosedInterval{Float64}}...)::Vector{<:Material} =
    filter(db, Material, Dict(prs...))

function Base.filter(db::SQLite.DB, ::Type{Material}, filt::Dict{Element, ClosedInterval{Float64}})::Vector{<:Material}
    cmds, args = String[], Any[]
    for (elm, ci) in filt
        push!(cmds, "SELECT MATKEY FROM MASSFRACTION WHERE MFZ=? AND MFC>=? and MFC<=?")
        append!(args, [ z(elm), minimum(ci), maximum(ci) ])
    end
    stmt = SQLite.Stmt(db, join(cmds," INTERSECT ")*";")
    q = DBInterface.execute(stmt, args)
    return [ read(db, Material, r[:MATKEY]) for r in q ]
end

function Base.similar(db::SQLite.DB, mat::Material, tol::Float64)::Vector{<:Material}
    interval(el) = max(0.0,mat[el]-tol)..(mat[el]+tol)
    return filter(db, Material, Dict(elm=>interval(elm) for elm in keys(mat)))
end
