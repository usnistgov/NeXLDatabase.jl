module NeXLDatabase

using SQLite
using Dates
using DataFrames
using IntervalSets
using Reexport

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
        "person", "laboratory", "labmembers", #
        "sample", "project", #
        "instrument", "detector", #
        "artifact", "spectrum", "fitspec", #
        "kratio" #
    )
    for tbl in tables
        if (length(existing)==0) || (!(uppercase(tbl) in existing.name))
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
include("helpers.jl")

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

export unknowns, references, dbreferences
export constructFitSpectra

end # module
