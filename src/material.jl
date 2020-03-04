export has

using IntervalSets

function has(db::SQLite.DB, ::Type{Material}, matname::AbstractString)::Bool
    stmt = SQLite.Stmt(db, "SELECT PKEY FROM MATERIAL WHERE MATNAME=?;")
    r=DBInterface.execute(stmt, (matname, ))
    return !SQLite.done(r)
end

function Base.write(db::SQLite.DB, mat::Material)
    res = -1
    SQLite.transaction(db) do
        stmt1 = SQLite.Stmt(db, "INSERT INTO MATERIAL (MATNAME, MATDESCRIPTION, MATDENSITY) VALUES ( ?, ?, ? );")
        r = DBInterface.execute(stmt1, (name(mat), get(mat, :Description, ""), get(mat, :Density, missing)))
        res = DBInterface.lastrowid(r)
        stmt2 = SQLite.Stmt(db, "SELECT PKEY FROM MATERIAL WHERE MATNAME=?;")
        pkey = (DBInterface.execute(stmt2, (name(mat), )) |> DataFrame)[end,:PKEY]
        stmt3 = SQLite.Stmt(db, "INSERT INTO MASSFRACTION ( MATROWID, MFZ, MFC, MFUC, MFA ) VALUES ( ?, ?, ?, ?, ? )")
        foreach(elm->DBInterface.execute(stmt3, (pkey, z(elm), value(mat[elm]), σ(mat[elm]), get(mat.a, elm, 0.0))), keys(mat))
    end
    return res
end

function Base.read(db::SQLite.DB, ::Type{Material}, matname::AbstractString)::Material
    stmt1 = SQLite.Stmt(db, "SELECT * FROM MATERIAL WHERE MATNAME=?;")
    r1 = DBInterface.execute(stmt1, (matname, ))
    if SQLite.done(r1)
        error("No known material named '$(matname)'.")
    end
    df1 = r1 |> DataFrame
    row, den, desc = df1[end,:PKEY], df1[end,:MATDENSITY], df1[end,:MATDESCRIPTION]
    stmt2 = SQLite.Stmt(db, "SELECT * FROM MASSFRACTION WHERE MATROWID=?;")
    mfs = DBInterface.execute(stmt2, (row, )) |> DataFrame
    massfrac, aa = Dict{Int,UncertainValue}(), Dict{Int,Float64}()
    for mfrow in eachrow(mfs)
        @assert mfrow[:MATROWID]==row
        z, c, uc, a = mfrow[:MFZ], mfrow[:MFC], mfrow[:MFUC], mfrow[:MFA]
        massfrac[z] = uv(c,uc)
        a>=0 && (aa[z]=a)
    end
    return Material(matname, massfrac, den, aa, desc)
end

function Base.delete!(db::SQLite.DB, ::Type{Material}, matname::AbstractString)
    stmt1 = SQLite.Stmt(db, "SELECT PKEY, * FROM MATERIAL WHERE MATNAME=?;")
    r1 = DBInterface.execute(stmt1, (matname, ))
    if !SQLite.done(r1)
        df1 = r1 |> DataFrame
        SQLite.transaction(db) do
            stmt1 = SQLite.Stmt(db, "DELETE FROM MASSFRACTION where MATROWID=?;")
            DBInterface.execute(stmt1, (df1[end,:PKEY], ))
            stmt2 = SQLite.Stmt(db, "DELETE FROM MATERIAL where PKEY=?;")
            DBInterface.execute(stmt2, (df1[end,:PKEY], ))
        end
    end
end

Base.filter(db::SQLite.DB, ::Type{Material}, prs::Pair{Element, ClosedInterval{Float64}}...)::Vector{String} =
    filter(db, Material, Dict(prs...))

function Base.filter(db::SQLite.DB, ::Type{Material}, filt::Dict{Element, ClosedInterval{Float64}})::Vector{String}
    cmds, args = String[], Any[]
    for (elm, ci) in filt
        push!(cmds, "SELECT MATROWID FROM MASSFRACTION WHERE MFZ=? AND MFC>=? and MFC<=?")
        append!(args, [ z(elm), minimum(ci), maximum(ci) ])
    end
    stmt = SQLite.Stmt(db, join(cmdsol," INTERSECT ")*";")
    df = DBInterface.execute(stmt, args) |> DataFrame
    res = String[]
    for row in eachrow(df)
        stmt2 = SQLite.Stmt(db, "SELECT MATNAME FROM MATERIAL WHERE PKEY=?;")
        df2 = DBInterface.execute(stmt2, (row[:MATROWID], )) |> DataFrame
        if size(df2)[1] ≠ 0
            push!(res,df2[end,:MATNAME])
        end
    end
    return res
end
