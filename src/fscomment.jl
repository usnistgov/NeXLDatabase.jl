
struct DBFSComment 
    pkey::Int
    fitspectra::DBFitSpectra
    person::DBPerson
    datetime::DateTime
    comment::String
end

function Base.write(db::SQLite.DB, ::Type{DBFSComment}, dbfs::DBFitSpectra, dbp::DBPerson, comment::String)
    stmt1 = SQLite.Stmt(db, "INSERT INTO FSCOMMENT ( FITSPECTRA, PERSON, DATETIME, COMMENT ) VALUES ( ?, ?, ?, ? );")
    q = DBInterface.execute(stmt1, ( dbfs.pkey, dbp.pkey, Dates.datetime2julian(now()), comment ))
    return DBInterface.lastrowid(q)
end

function Base.read(db::SQLite.DB, ::Type{DBFSComment}, fitspectra::DBFitSpectra)::Vector{DBFSComment}
    stmt1 = SQLite.Stmt(db, "SELECT PKEY, FITSPECTRA, PERSON, DATETIME, COMMENT FROM FSCOMMENT WHERE FITSPECTRA=?;")
    q = DBInterface.execute(stmt1, ( fitspectra.pkey, ))
    res = DBFSComment[]
    while !SQLite.done(q)
        r = SQLite.Row(q)
        @assert r[:FITSPECTRA] == fitspectra.pkey
        c = DBFSComment(r[:PKEY], fitspectra, read(db, DBPerson, r[:PERSON]), Dates.julian2datetime(r[:DATETIME]), r[:COMMENT])
        push!(res, c)
    end
    return res
end