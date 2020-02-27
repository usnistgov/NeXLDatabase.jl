module NeXLDatabase

using NeXLCore
using NeXLSpectrum
using SQLite
using Dates
using DataFrames
using IntervalSets

export openNeXLDatabase

function openNeXLDatabase(filename::AbstractString)::SQLite.DB
    function stripcomment(ss)
        i=findfirst("--",ss)
        return i == nothing ? ss : ss[1:i.start-1]
    end
    function buildTable(tbl)
        path = dirname(pathof(@__MODULE__))
        cmd = readlines("$(path)/sql/$(tbl).sql")
        SQLite.execute(db, reduce(*, map(stripcomment, cmd)))
    end
    db = SQLite.DB(filename)
    existing = SQLite.tables(db)
    tables = (
        "material", "massfraction", #
        "person", "laboratory", "sample", #
        "instrument", "detector", #
        "spectrum",
        # "person", "laboratory", "labmembers", "instrument", "edsdetector", "sample", "spectrum"
    )
    for tbl in tables
        if (length(existing)==0) || (!(uppercase(tbl) in existing.name))
            buildTable(tbl)
            @info "Building table $(tbl)."
        end
    end
    return db
end

include("material.jl")

end # module
