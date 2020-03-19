using SQLite
using NeXLCore
using IntervalSets

struct DBFitSpectrum
    fitspectra::Int
    spectrum::DBSpectrum
end

Base.show(io::IO, dbf::DBFitSpectrum) =
    print(io, "Fit[$(dbf.spectrum.name)]")

Base.convert(::Type{Spectrum}, dbfs::DBFitSpectrum) = Base.convert(Spectrum, dbfs.spectrum)

function Base.write(db::SQLite.DB, ::Type{DBFitSpectrum}, fitspectra::Int, spectrum::Int)::Int
    stmt1 = SQLite.Stmt(db, "INSERT INTO FITSPECTRUM(FITSPECTRA, SPECTRUM ) VALUES ( ?, ? );")
    q = DBInterface.execute(stmt1, ( fitspectra, spectrum ))
    return  DBInterface.lastrowid(q)
end

struct DBReference
    pkey::Int
    fitspectra::Int
    spectrum::DBSpectrum
    elements::Vector{Element}
    # refroi::Vector{DBReferenceROI}
end

Base.show(io::IO, dbr::DBReference) =
    print(io,"Reference[$(dbr.spectrum.name) with $(join(symbol.(dbr.elements),','))]")

Base.convert(::Type{Spectrum}, dbr::DBReference) = Base.convert(Spectrum, dbr.spectrum)

function Base.write(db::SQLite.DB, ::Type{DBReference}, fitspectra::Int, spectrum::Int, elements::Vector{Element})::Int
    stmt1 = SQLite.Stmt(db, "INSERT INTO REFERENCESPECTRUM(FITSPECTRA, SPECTRUM, ELEMENTS) VALUES ( ?, ?, ? );")
    q = DBInterface.execute(stmt1, ( fitspectra, spectrum, _elmstostr(elements)))
    return  DBInterface.lastrowid(q)
end

struct DBFitSpectra
    pkey::Int
    project::DBProject
    detector::DBDetector
    elements::Vector{Element}
    fitspectrum::Vector{DBFitSpectrum}
    refspectrum::Vector{DBReference}
end

function Base.show(io::IO, dbfs::DBFitSpectra)
    println(io, "   Index = $(dbfs.pkey)")
    println(io, " Project = $(repr(dbfs.project))")
    println(io, "Elements = $(symbol.(dbfs.elements))")
    println(io, "Detector = $(repr(dbfs.detector))")
    print(io, "==== Unknowns ====")
    for dbf in dbfs.fitspectrum
        print(io, "\n\t$dbf")
    end
    print(io,"\n==== References ====")
    for elm in dbfs.elements
        print(io, "\n\t$(symbol(elm)) = $(join(dbreference(dbfs, elm),','))")
    end
end

unknowns(fbfs::DBFitSpectra)::Vector{Spectrum} =
    map(fs->convert(Spectrum, fs), fbfs.fitspectrum)

reference(fbfs::DBFitSpectra, elm::Element)::Vector{Spectrum} =
    convert.(Spectrum, dbreference(fbfs, elm))

dbreference(fbfs::DBFitSpectra, elm::Element)::Vector{DBReference} =
    collect(filter(rs->elm in rs.elements, fbfs.refspectrum))


charXRayLabels(#
    dbr::DBReference, #
    elm::Element, #
    det::Detector, #
    ampl::Float64, #
    maxE::Float64=1.0e6)::Vector{CharXRayLabel} =
    NeXLSpectrum.charXRayLabels(convert(Spectrum,dbr.spectrum), elm, dbr.elements, det, ampl, maxE)

PeriodicTable.elements(fbfs::DBFitSpectra) = fbfs.elements

_elmstostr(elms::Vector{Element}) = join(symbol.(elms),',')
_strtoelms(str::String) = parse.(Element,strip.(split(str,',')))

function Base.write(db::SQLite.DB, ::Type{DBFitSpectra}, projKey::Int, detKey::Int, elms::Vector{Element})::Int
    stmt1 = SQLite.Stmt(db, "INSERT INTO FITSPECTRA(PROJECT, DETECTOR, ELEMENTS) VALUES( ?, ?, ?);")
    q = DBInterface.execute(stmt1, ( projKey, detKey, _elmstostr(elms)))
    return  DBInterface.lastrowid(q)
end

function Base.read(db::SQLite.DB, ::Type{DBFitSpectra}, pkey::Int)::DBFitSpectra
    stmt1 = SQLite.Stmt(db, "SELECT * FROM FITSPECTRA WHERE PKEY=?;")
    q1 = DBInterface.execute(stmt1, ( pkey, ))
    if SQLite.done(q1)
        error("No fit spectra record with pkey = $pkey.")
    end
    r1=SQLite.Row(q1)
    @assert r1[:PKEY]==pkey "Mismatching pkey in DBFitSpectrum"
    project = read(db, DBProject, r1[:PROJECT])
    detector = read(db, DBDetector, r1[:DETECTOR])
    elms = _strtoelms(r1[:ELEMENTS])
    stmt2 = SQLite.Stmt(db, "SELECT * FROM FITSPECTRUM WHERE FITSPECTRA=?;")
    q2 = DBInterface.execute(stmt2, ( pkey, ))
    tobefit = DBFitSpectrum[]
    for r2 in q2
        @assert r2[:FITSPECTRA]==pkey
        spec = read(db, DBSpectrum, r2[:SPECTRUM])
        push!(tobefit, DBFitSpectrum(pkey, spec))
    end
    stmt3 = SQLite.Stmt(db, "SELECT * FROM REFERENCESPECTRUM WHERE FITSPECTRA=?;")
    q3 = DBInterface.execute(stmt3, ( pkey, ))
    refs = DBReference[]
    for r3 in q3
        @assert r3[:FITSPECTRA]==pkey
        spec = read(db, DBSpectrum, r3[:SPECTRUM])
        push!(refs, DBReference(r3[:PKEY], r3[:FITSPECTRA], spec, _strtoelms(r3[:ELEMENTS])))
    end
    return DBFitSpectra(pkey, project, detector, elms, tobefit, refs)
end

function Base.delete!(db::SQLite.DB, ::Type{DBFitSpectra}, pkey::Int)
    stmt1 = SQLite.Stmt(db,"DELETE FROM FITSPECTRA WHERE PKEY=?;")
    stmt2 = SQLite.Stmt(db,"DELETE FROM REFERENCESPECTRUM WHERE FITSPECTRA=?;")
    stmt3 = SQLite.Stmt(db,"DELETE FROM FITSPECTRUM WHERE FITSPECTRA=?;")
    DBInterface.execute(stmt3, (pkey, ))
    DBInterface.execute(stmt2, (pkey, ))
    DBInterface.execute(stmt1, (pkey, ))
end
