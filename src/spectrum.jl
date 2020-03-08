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
    data::DBArtifact
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
    artifact = write(db, DBArtifact, filename, "SPECTRUM", format)
    stmt1 = SQLite.Stmt(db, "INSERT INTO SPECTRUM ( DETECTOR, BEAMENERGY, COMPOSITION, COLLECTEDBY, SAMPLE, COLLECTED, NAME, ARTIFACT ) VALUES ( ?, ?, ?, ?, ?, ?, ?, ? );")
    results = DBInterface.execute(stmt1, (det, e0, comp, collectedBy, sample, collected, name, artifact ))
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
    coll = read(db, DPPerson, r[:COLLECTEDBY])
    samp = read(db, DBSample, r[:SAMPLE])
    artifact = read(db, DBArtifact, r[:ARTIFACT])
    return DBSpectrum( r[:PKEY], det, r[:BEAMENERGY], mat, coll, samp, r[:COLLECTED], r[:NAME], artifact)
end
