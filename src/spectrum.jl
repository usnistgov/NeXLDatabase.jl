#CREATE TABLE SPECTRUM (
#    PKEY INTEGER PRIMARY KEY AUTOINCREMENT,
#    DETECTOR INTEGER NOT NULL, -- Need to know the detector ()
#    BEAMENERGY REAL NOT NULL, -- IN EV
#    COMPOSITION INTEGER,
#    COLLECTEDBY INTEGER NOT NULL,  -- PERSON(PKEY)
#    SAMPLE INTEGER NOT NULL, -- SAMPLE(PKEY)
#    COLLECTED TIMESTAMP NOT NULL,
#    NAME TEXT,
#    ARTIFACT INT NOT NULL, -- The spectrum data in a standard spectrum file format
#    FOREIGN KEY(DETECTOR) REFERENCES DETECTOR(PKEY),
#    FOREIGN KEY(COMPOSITION) REFERENCES MATERIAL(PKEY),
#    FOREIGN KEY(COLLECTEDBY) REFERENCES PERSON(PKEY),
#    FOREIGN KEY(SAMPLE) REFERENCES SAMPLE(PKEY),
#    FOREIGN KEY(ARTIFACT) REFERENCES ARTIFACT(PKEY)
#);

struct DBSpectrum
    pkey::Int
    detector::DBDetector
    beamenergy::Float64
    composition::Union{Material,Missing}
    collectedby::DBPerson
    sample::DBSample
    collected::DateTime
    name::String
    format::String
    data::Vector{UInt8}
end

function Base.write(#
        db::SQLite.DB, #
        ::Type{DBSpectrum}, #
        det::Int, #
        e0::Float64, #
        comp::Int, #
        collectedBy::Int, #
        sample::Int, #
        collected::DateTime, #
        name::String, #
        filename::String,
        format::String)::Int
    if !((format=="EMSA") || (format=="ASPEX"))
        error("Unknown format $(format) in write(db, DBSpectrum,...).")
    end
    data = Mmap.mmap(filename, Vector{UInt8}, (stat(filename).size, ))
    stmt1 = SQLite.Stmt(db, "INSERT INTO SPECTRUM ( DETECTOR, BEAMENERGY, COMPOSITION, COLLECTEDBY, SAMPLE, COLLECTED, NAME, FORMAT, DATA ) VALUES ( ?, ?, ?, ?, ?, ?, ?, ?, ? );")
    results = DBInterface.execute(stmt1, (det, e0, comp, collectedBy, sample, collected, name, format, data ))
    return  DBInterface.lastrowid(results)
end

function Base.write(#
        db::SQLite.DB, #
        ::Type{DBSpectrum}, #
        det::DBDetector, #
        e0::Float64, #
        comp::Union{Material, Missing}, #
        collectedBy::DBPerson, #
        sample::DBSample, #
        collected::DateTime, #
        name::String, #
        filename::String,
        format::String)::Int
    compIdx = ismissing(comp) ? -1 : write(db, comp)
    return write(db, DBSpectrum, det.pkey, e0, compidx, collectedBy.pkey, sample.pkey, collected, name, filename, format)
end

function Base.read(db::SQLite.DB, ::Type{DBSpectrum}, pkey::Int)::DBSpectrum
    stmt1 = SQLite.Stmt(db, "SELECT * FROM SPECTRUM WHERE PKEY=?;")
    q = DBInterface.execute(stmt1, (pkey, ))
    if SQLite.done(q)
        error("No spectrum found with pkey=$(pkey)")
    end
    r=SQLite.Row(q)
    mat = r[:COMPOSITION] > 0 ? read(db,Material,r[:COMPOSITION]) : missing
    det = read(db, DBDetector, r[:DETECTOR])
    coll = read(db, DBPerson, r[:COLLECTEDBY])
    samp = read(db, DBSample, r[:SAMPLE])
    return DBSpectrum( r[:PKEY], det, r[:BEAMENERGY], mat, coll, samp, r[:COLLECTED], r[:NAME], r[:FORMAT], r[:DATA])
end

function Base.convert(::Type{Spectrum}, dbspec::DBSpectrum)::Spectrum
    if dbspec.format=="EMSA"
        return readEMSA(IOBuffer(dbspec.data), Float64)
    elseif dbspec.format=="ASPEX"
        return readAspexTIFF(IOBuffer(dbspec.data); withImgs=true)
    else
        error("Unknown spectrum format $(art.format).")
    end
end

struct DBProjectSpectrum
    pkey::Int
    project::Int
    spectrum::Int
end

function Base.write(db::SQLite.DB, ::Type{DBProjectSpectrum}, projectkey::Int, spectrumkey::Int)::Int
    stmt1 = SQLite.Stmt(db, "INSERT INTO PROJECTSPECTRUM ( PROJECT, SPECTRUM ) VALUES ( ?, ?)")
    q = DBInterface.execute(stmt1, ( projectkey, spectrumkey ))
    return DBInterface.lastrowid(q)
end

function Base.read(db::SQLite.DB, ::Type{DBProject}, ::Type{DBProjectSpectrum}, projectkey::Int)::Vector{DBProjectSpectrum}
    stmt1 = SQLite.Stmt(db, "SELECT * FROM PROJECTSPECTRUM WHERE PROJECT=?;")
    q = DBInterface.execute(stmt1, ( parent.pkey, ))
    return [ DBProjectSpectrum(r[:PKEY], r[:PROJECT], r[:SPECTRUM]) for r in q ]
end

function Base.read(db::SQLite.DB, ::Type{DBProject}, ::Type{DBSpectrum}, projectkey::Int)::Vector{DBSpectrum}
    stmt1 = SQLite.Stmt(db, "SELECT * FROM PROJECTSPECTRUM WHERE PROJECT=?;")
    q = DBInterface.execute(stmt1, ( projectkey, ))
    return [ read(db, DBSpectrum, r[:SPECTRUM]) for r in q ]
end
