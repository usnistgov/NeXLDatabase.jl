module NeXLDatabase

using NeXLCore
using NeXLSpectrum
using SQLite
using Dates

function openDB(filename::AbstractString)
    function stripcomment(ss)
        i=findfirst("--",ss)
        return i == nothing ? ss : ss[1:i.start-1]
    end
    function buildTable(tbl)
        cmd = readlines("sql/$(tbl).sql")
        SQLite.Query(db, reduce(*, map(stripcomment, cmd)))
    end
    db = SQLite.DB(filename)
    existing = SQLite.tables(db)
    tables = (
        "material", "massfraction", #
        # "person", "laboratory", "labmembers", "instrument", "edsdetector", "sample", "spectrum"
    )
    for tbl in tables
        if !(uppercase(tbl) in existing)
            buildTable(tbl)
            @info "Building table $(tbl)."
        end
    end
end


function write(db::SQLite, mat::Material, force::Boolean)
    stmt2 = SQLite.Stmt(db, "SELECT ROWID FROM MATERIAL WHERE MATNAME=?;")
    SQLite.bind!(stmt1, 1, name(mat))
    r=SQLite.Query(stmt1)
    if


    stmt1 = SQLite.Stmt(db, "INSERT INTO MATERIAL (MATNAME, MATDESCRIPTION, MATDENSITY) VALUES ( ?, ?, ? );")
    SQLite.bind!(stmt1, 1, name(mat))
    SQLite.bind!(stmt1, 2, get(mat, :Description, missing))
    SQLite.bind!(stmt1, 2, get(mat, :Density, missing))
    SQLite.Query(stmt1)
    stmt2 = SQLite.Stmt(db, "SELECT ROWID FROM MATERIAL WHERE MATNAME=?;")
    SQLite.bind!(stmt2, 1, name(mat))
    rowid = (SQLite.Query(stmt2) |> DataFrame)[end,:rowid]
    stmt2 = SQLite.Stmt(db, "INSERT INTO MASSFRACTION ( MATROWID, MFZ, MFC, MFUC, MFA ) VALUES ( ?, ?, ?, ?, ? )")
    for elm in keys(mat)
        SQLite.bind!(stmt2, 1, rowid)
        SQLite.bind!(stmt2, 2, z(elm))
        SQLite.bind!(stmt2, 3, mat[elm])
        SQLite.bind!(stmt2, 4, missing)
        SQLite.bind!(stmt2, 5, get(mat.a, elm, missing))
        SQLite.Query(stmt1)
    end
end

function read(db::SQLite, ::Type{Material}, matname::AbstractString)::Vector{Material}
    stmt1 = SQLite.Stmt("SELECT ROWID, * FROM MATERIAL WHERE MATNAME=?;")
    df1 = SQLite.Query(stmt2) |> DataFrame
    res = Material[]
    for row in eachrow(df1)
        name, desc, den = row[:MATNAME], row[:MATDESCRIPTION], row[:MATDENSITY]
        stmt2 = SQLite.Stmt(db, "SELECT * FROM MASSFRACTION WHERE MATROWID=?;")
        SQLite.bind!(stmt2, row[:rowid])
        mfs = SQLite.Query(stmt2) |> DataFrame
        massfrac, aa = Dict{Element,Float64}(), Dict{Element,Float64}()
        for mfrow in eachrow(mfs)
            @assert mfrow[:MATROWID]==row[:rowid]
            z, c, a = mfrow[:MFZ], mfrow[:MFC], mfrow[:MFA]
            massfrac[z]=c
            if !ismissing(a)
                aa[z]=a
            end
        end
        push!(res,Material(name, massfrac, den, aa, desc))
    end
    return res
end






end



    material INTEGER NOT NULL,
    z INTEGER NOT NULL,
    c REAL NOT NULL,
    uc REAL,

end

function read(db::SQLite, matname::Material)

end # module
