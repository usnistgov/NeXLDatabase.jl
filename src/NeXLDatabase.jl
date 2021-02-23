module NeXLDatabase

using SQLite
using Dates
using DataFrames
using IntervalSets
using Reexport
using Requires

@reexport using NeXLSpectrum

export openNeXLDatabase

function openNeXLDatabase(filename::AbstractString)::SQLite.DB
    function stripcomment(ss)
        i=findfirst("--",ss)
        return i == nothing ? ss : ss[1:i.start-1]
    end
    function buildTable(tbl)
        path = dirname(pathof(@__MODULE__))
        cmds = reduce(*, map(stripcomment, readlines("$(path)/sql/$(tbl).sql")))
        for cmd in strip.(split(cmds,";"))
            if length(cmd)>0
                SQLite.execute(db, cmd)
            end
        end
    end
    db = SQLite.DB(filename)
    existing = SQLite.tables(db)
    tables = (
        "material", "massfraction", #
        "person", "laboratory", "labmember", #
        "sample", "project", #
        "instrument", "detector", #
        "artifact", "spectrum", "fitspectra", #
        "kratio", "standardfor", "fscomment" #
    )
    for tbl in tables
        if (!haskey(existing, :name)) || (!(uppercase(tbl) in existing.name))
            # @info "Creating database table $(tbl)."
            buildTable(tbl)
        end
    end
    return db
end

include("material.jl")
include("person.jl")
include("laboratory.jl")
include("instrument.jl")
include("sample.jl")
include("artifact.jl")
include("project.jl")
include("spectrum.jl")
include("fitspec.jl")
include("kratio.jl")
include("helpers.jl")
include("standardfor.jl")
include("fscomment.jl")

export DBPerson
export DBLaboratory
export DBInstrument
export DBDetector
export DBArtifact
export DBSpectrum
export DBMember
export DBSample
export DBProject
export DBProjectSpectrum
export find
export DBFitSpectra
export DBFitSpectrum
export DBReference
export DBKRatio
export DBStandardFor
export DBFSComment

export measured, references, dbreferences
export constructFitSpectra

function __init__()
    @require Gadfly = "c91e804a-d5a3-530f-b6f0-dfbca275c004" include("gadflysupport.jl")
end

end # module
