using Test
using NeXLDatabase
#using NeXLSpectrum
using Dates

@testset begin
    dbname = tempname()
    db = openNeXLDatabase(dbname)
    write(db, DBPerson, "Harvey Sun Beetle", "hsb@gmail.com")
    ld1 = write(db, DBPerson, "Butterbean Q. Grenfeld, III", "bqg@gmail.com")
    ld2 = write(db, DBPerson, "Jeanne I. Bottle", "jib@gmail.com")

    l1 = write(db, DBLaboratory, "OpenLab", read(db, DBPerson, ld1))
    l2 = write(db, DBLaboratory, "ClosedLab", read(db, DBPerson, ld2))

    lm1 = write(db, DBMember, l1, ld1)
    lm1 = write(db, DBMember, l2, ld2)

    i1 = write(db, DBInstrument, l1, "JEOL", "JXA-7001", "H103")
    i2 = write(db, DBInstrument, l1, "TESCAN", "MIRA3", "H119")
    i3 = write(db, DBInstrument, l2, "Hitachi", "SU-2000", "Gr19")
    i4 = write(db, DBInstrument, l2, "Cameca", "SX-5", "Gr22")

    d1 = write(db, DBDetector, i1, "Bruker", "Esprit 6|30", "30 mm² SDD")
    d2 = write(db, DBDetector, i2, "Oxford", "XMAX 100", "100 mm² SDD")
    d3 = write(db, DBDetector, i3, "EDAX", "Octane", "30 mm² SDD")
    d4 = write(db, DBDetector, i4, "Thermo", "UltraDry", "100 mm² SDD")
    d5 = write(db, DBDetector, i2, "Pulsetor", "Torrent", "4 × 30 mm² SDD")

    using NeXLCore
    mats = NeXLCore.compositionlibrary()
    for (name, mat) in mats
        write(db, mat)
    end

    k240 = read(db, Material, "K240")
    @test isapprox(value(k240[n"Ba"]), 0.2687, atol = 0.000001)
    @test NeXLDatabase.find(db, DBPerson, "jib@gmail.com") == ld2
    @test NeXLDatabase.find(db, DBPerson, "unknown@gmail.com") == -1
    @test NeXLDatabase.find(db, DBPerson, "bqg@gmail.com") == ld1
    @test NeXLDatabase.find(db, DBPerson, "nicholas.ritchie@nist.gov") == 1

    s1 = write(db, DBSample, l1, "SPI REP", "Rare Earth Phosphates")
    for mat in ("CeP5O14", "LaP5O14", "NdP5O14", "PrP5O14", "SmP5O14", "YP5O14")
        midx = write(db, parse(Material, mat))
        write(
            db,
            DBSpectrum,
            d5,
            20.0e3,
            midx,
            ld2,
            s1,
            now(),
            mat * " standard",
            joinpath(joinpath(@__DIR__,"spectra"), mat * " std.msa"),
            "EMSA",
        )
    end
# write(db, DBArtifact, )
end
