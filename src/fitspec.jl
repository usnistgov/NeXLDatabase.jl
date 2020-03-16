using SQLite
using NeXLCore
using IntervalSets

struct DBFitSpectrum
    fitspectra::Int
    spectrum::DBSpectrum
end

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

function Base.write(db::SQLite.DB, ::Type{DBReference}, fitspectra::Int, spectrum::Int, elements::Vector{Element})::Int
    stmt1 = SQLite.Stmt(db, "INSERT INTO REFERENCESPECTRUM(FITSPECTRA, SPECTRUM, ELEMENTS) VALUES ( ?, ?, ? );")
    q = DBInterface.execute(stmt1, ( fitspectra, spectrum, _elmstostr(elements)))
    return  DBInterface.lastrowid(q)
end

struct DBFitSpectra
    pkey::Int
    name::String
    project::DBProject
    elements::Vector{Element}
    fitspectrum::Vector{DBFitSpectrum}
    refspectrum::Vector{DBReference}
end

_elmstostr(elms::Vector{Element}) = join(symbol.(elms),',')
_strtoelms(str::String) = parse.(Element,strip.(split(str,',')))

function Base.write(db::SQLite.DB, ::Type{DBFitSpectra}, name::String, projKey::Int, elms::Vector{Element})::Int
    stmt1 = SQLite.Stmt(db, "INSERT INTO FITSPECTRA(NAME, PROJECT, ELEMENTS) VALUES( ?, ?, ?);")
    q = DBInterface.execute(stmt1, ( name, projKey, _elmstostr(elms)))
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
    name, project = r1[:NAME], read(db, DBProject, r1[:PROJECT])
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
        elms = _strtoelms(r3[:ELEMENTS])
        #stmt4 = SQLite.Stmt(db,"SELECT PKEY FROM REFERENCEROI WHERE REFPKEY=?;")
        #q4 = DBInterface.execute(stmt4, ( r3[:PKEY]))
        #refrois = DBReferenceROI[]
        #for r4 in q4
        #    push!(refrois, read(db,DBReferenceROI,r4[:PKEY]))
        #end
        push!(refs, DBReference(r3[:PKEY], r3[:FITSPECTRA], spec, elms))
    end
    return DBFitSpectra(pkey, name, project, elms, tobefit, refs)
end

#struct DBReferenceROI
#    pkey::Int
#    refpkey::Int # REFERENCE(PKEY) or DBReference.pkey
#    atomicnumber::Int
#    low::Float64 # In eV
#    high::Float64 # In eV
#end

#function Base.write(db::SQLite.DB, ::DBReferenceROI, refpkey::Int, element::Element, roi::ClosedInterval{Float64})::Int
#    stmt1 = SQLite.Stmt(db, "INSERT INTO REFERENCESPECTRUM(REFPKEY, ATOMICNUMBER, LOW, HIGH) VALUES ( ?, ?, ?, ? );")
#    q = DBInterface.execute(stmt1, ( refpkey, element.atomic_number, roi.left, roi.right ))
#    return  DBInterface.lastrowid(results)
#end

#_intervalstostr(intervals::Dict{Element, Vector{ClosedInterval{Float64}}})::String =
#    join((elm.symbol*"=("*join(repr.(i),',')*')' for (elm, i) in intervals),';')

#function _strtointervals(str::String)
#    ci(ss)::Vector{ClosedInterval{Float64}} =
#        [ ClosedInterval(parse(Float64,i[1]), parse(Float64,i[2])) for i in split.(strip.(split(ss[2:end-1],',')),r"\.\.") ]
#    ts = split.(split(str,";"),'=')
#    return Dict( parse(Element,t[1]) => ci(t[2]) for t in ts)
#end
