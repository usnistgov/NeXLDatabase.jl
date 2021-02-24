
struct DBFSComment 
    pkey::Int
    campaign::DBCampaign
    person::DBPerson
    datetime::DateTime
    comment::String
end


function Base.write(db::SQLite.DB, ::Type{DBFSComment}, campaign::Int, dbp::DBPerson, comment::String)
    stmt1 = SQLite.Stmt(db, "INSERT INTO CAMPAIGNCOMMENT ( CAMPAIGN, PERSON, DATETIME, COMMENT ) VALUES ( ?, ?, ?, ? );")
    q = DBInterface.execute(stmt1, ( campaign, dbp.pkey, Dates.datetime2julian(now()), comment ))
    return DBInterface.lastrowid(q)
end
function Base.write(db::SQLite.DB, ::Type{DBFSComment}, campaign::DBCampaign, dbp::DBPerson, comment::String)
    write(db, DBFSComment, campaign.pkey, dbp, comment)
end

function Base.read(db::SQLite.DB, ::Type{DBFSComment}, campaign::DBCampaign)::Vector{DBFSComment}
    stmt1 = SQLite.Stmt(db, "SELECT PKEY, CAMPAIGN, PERSON, DATETIME, COMMENT FROM CAMPAIGNCOMMENT WHERE CAMPAIGN=?;")
    q = DBInterface.execute(stmt1, ( campaign.pkey, ))
    res = DBFSComment[]
    while !SQLite.done(q)
        r = SQLite.Row(q)
        @assert r[:CAMPAIGN] == campaign.pkey
        c = DBFSComment(r[:PKEY], campaign, read(db, DBPerson, r[:PERSON]), Dates.julian2datetime(r[:DATETIME]), r[:COMMENT])
        push!(res, c)
    end
    return res
end