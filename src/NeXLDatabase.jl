module NeXLDatabase

using NeXLCore
using NeXLSpectrum
using SQLite
using Dates

const createPerson = """



function DB(filename::AbstractString)
    db = SQLite.DB(filename)
    tbls = SQLite.tables(db)
    if ! ("Person" in tbls)

    end
    if !("Laboratory" in tbls)

    end
    if !("Project" in tbls)

    end
    if !("Sample" in tbls)

    end
    if !("Analysis" in tbls)

    end
    if !("Material" in tbls)

    end
end

end # module
