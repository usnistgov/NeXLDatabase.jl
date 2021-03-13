struct DBSpectrum
    database::SQLite.DB
    pkey::Int
    detector::DBDetector
    beamenergy::Float64
    composition::Union{Material,Missing}
    collectedby::DBPerson
    sample::DBSample
    collected::DateTime
    name::String
    artifact::DBArtifact
end

function sniffFormat(fn)
    if NeXLSpectrum.isemsa(fn)
        return "EMSA"
    elseif NeXLSpectrum.isAspexTIFF(fn)
        return "ASPEX"
    else
        error("Unknown file type in $fn.")
    end
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
    artifact = write(db, DBArtifact, filename, format)
    stmt1 = SQLite.Stmt(db, "INSERT INTO SPECTRUM ( DETECTOR, BEAMENERGY, COMPOSITION, COLLECTEDBY, SAMPLE, COLLECTED, NAME, ARTIFACT ) VALUES ( ?, ?, ?, ?, ?, ?, ?, ? );")
    results = DBInterface.execute(stmt1, (det, e0, comp, collectedBy, sample, Dates.datetime2julian(collected), name, artifact ))
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
    compidx = ismissing(comp) ? -1 : write(db, comp)
    return write(db, DBSpectrum, det.pkey, e0, compidx, collectedBy.pkey, sample.pkey, collected, name, filename, format)
end

function Base.read(db::SQLite.DB, ::Type{DBSpectrum}, pkey::Int)::DBSpectrum
    stmt1 = SQLite.Stmt(db, "SELECT * FROM SPECTRUM WHERE PKEY=?;")
    q = DBInterface.execute(stmt1, (pkey, ))
    if SQLite.done(q)
        error("No spectrum found with pkey=$(pkey)")
    end
    r=SQLite.Row(q)
    mat = r[:COMPOSITION] >= 0 ? read(db,Material,r[:COMPOSITION]) : missing
    det = read(db, DBDetector, r[:DETECTOR])
    colby = read(db, DBPerson, r[:COLLECTEDBY])
    samp = read(db, DBSample, r[:SAMPLE])
    art = read(db, DBArtifact, r[:ARTIFACT])
    acq = Dates.julian2datetime(r[:COLLECTED])
    return DBSpectrum(db, r[:PKEY], det, r[:BEAMENERGY], mat, colby, samp, acq, r[:NAME], art)
end

function NeXLUncertainties.asa(::Type{Spectrum}, dbspec::DBSpectrum)::Spectrum
    res = asa(Spectrum, dbspec.artifact)
    res[:Name] = dbspec.name
    res[:Sample] = repr(dbspec.sample)
    res[:Owner] = dbspec.collectedby.name
    res[:Detector] = convert(BasicEDS, dbspec.detector, length(res))
    res[:PKEY] = dbspec.pkey
    if !ismissing(dbspec.composition)
        res[:Composition] = dbspec.composition
    end
    return res
end
