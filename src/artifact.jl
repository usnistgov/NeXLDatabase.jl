using Mmap
using SQLite
using SHA

struct DBArtifact
    database::SQLite.DB
    pkey::Int
    format::String # EMSA, ASPEX, PNG, JPEG, ...
    filename::String
    data::Vector{UInt8}
end

Base.show(io::IO, art::DBArtifact) = print(io, "Format: $(art.format)\nSource: $(art.filename)")

function Base.write(db::SQLite.DB, ::Type{DBArtifact}, filename::String, format::String)::Int
    # @assert format in ( "EMSA", "ASPEX", "BRUKER SPX", "PNG", "JPEG", "TIFF" ) "Unknown format in write artifact: $format"
    @assert isfile(filename) "No such file in write artifact to database: $filename"
    @assert stat(filename).size > 0 "Null file in write artifact to database: $filename"
    # Check by SHA256 whether the artifact already exists in the database
    sha=open(filename) do f
           bytes2hex(sha2_256(f))
    end
    stmt0 = SQLite.Stmt(db, "SELECT PKEY FROM ARTIFACT WHERE SHA256=?;")
    sr = DBInterface.execute(stmt0, (sha,))
    if SQLite.done(sr)
        data = Mmap.mmap(filename, Vector{UInt8}, (stat(filename).size, ))
        stmt1 = SQLite.Stmt(db, "INSERT INTO ARTIFACT ( FORMAT, FILENAME, DATA, SHA256) VALUES ( ?, ?, ?, ? );")
        results = DBInterface.execute(stmt1, ( uppercase(format), filename, data, sha ))
        return  DBInterface.lastrowid(results)
    else
        #pk = SQLite.Row(sr)[:PKEY]
        #@warn "$(basename(filename)) already exists in the database as PKEY=$pk."
        return SQLite.Row(sr)[:PKEY]
    end
end

function Base.read(db::SQLite.DB, ::Type{DBArtifact}, pkey::Int)
    stmt1 = SQLite.Stmt(db, "SELECT * FROM ARTIFACT WHERE PKEY=?;")
    q = DBInterface.execute(stmt1, (pkey, ))
    if SQLite.done(q)
        error("No artifact found with pkey=$(pkey)")
    end
    r=SQLite.Row(q)
    return DBArtifact(db, r[:PKEY], r[:FORMAT], r[:FILENAME], r[:DATA] )
end

Base.read(db::SQLite.DB, ::Type{Spectrum}, pkey::Int)::Spectrum =
     asa(Spectrum, read(db,DBArtifact,pkey))

function NeXLUncertainties.asa(::Type{Spectrum}, artifact::DBArtifact)::Spectrum
    if artifact.format=="EMSA"
        return loadspectrum(ISOEMSA, IOBuffer(artifact.data), Float64)
    elseif artifact.format=="ASPEX"
        return loadspectrum(ASPEXTIFF, IOBuffer(artifact.data); withImgs=false)
    elseif artifact.format=="BRUKER SPX"
        return readbrukerspx(IOBuffer(artifact.data))
    else
        error("Unexpected format $(art.format) for a spectrum file.")
    end
end
