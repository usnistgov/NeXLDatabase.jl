using Test
using NeXLCore
using NeXLDatabase
using SQLite
using Dates
using Statistics
using Pkg.Artifacts

function tifffilename(i)
    res = "$i.tif"
    return repeat('0', max(0, 9 - length(res))) * res
end

# Download the necessary data using the Artifact mechanism from Google Drive
zip = artifact"shooter0"
#dbname = ":memory:"
dbname = "C:\\Users\\nritchie\\Desktop\\test.db" # tempname()
db = openNeXLDatabase(dbname)
ld1 = write(db, DBPerson, "Butterbean Q. Grenfeld, III", "bqg@gmail.com")
ld2 = write(db, DBPerson, "Jeanne I. Bottle", "jib@gmail.com")
ld3 = write(db, DBPerson, "Harvey Sun Beetle", "hsb@gmail.com")

l1 = write(db, DBLaboratory, "OpenLab", read(db, DBPerson, ld1))
l2 = write(db, DBLaboratory, "ClosedLab", read(db, DBPerson, ld2))

write(db, DBMember, l1, 1)
write(db, DBMember, l2, 2)
write(db, DBMember, l2, ld3)

i1 = write(db, DBInstrument, l1, "JEOL", "JXA-7001", "H103")
i2 = write(db, DBInstrument, l1, "TESCAN", "MIRA3", "H119")
i3 = write(db, DBInstrument, l2, "Hitachi", "SU-2000", "Gr19")
i4 = write(db, DBInstrument, l2, "Cameca", "SX-5", "Gr22")

d1 = write(db, DBDetector, i1, "Bruker", "Esprit 6|30", "30 mm² SDD", 125.0, 106, -495.0, 5.0, 4, 21, 55, 94)
d2 = write(db, DBDetector, i2, "Oxford", "XMAX 100", "100 mm² SDD", 130.0, 20, 0.0, 5.0, 4, 18, 50, 90)
d3 = write(db, DBDetector, i3, "EDAX", "Octane", "30 mm² SDD", 128.0, 20, 0.0, 5.0, 4, 21, 55, 94)
d4 = write(db, DBDetector, i4, "Thermo", "UltraDry", "100 mm² SDD", 126.0, 20, 0.0, 10.0, 4, 21, 55, 94)
d5 = write(db, DBDetector, i2, "Pulsetor", "Torrent", "4 × 30 mm² SDD", 132.0, 10, 0.0, 10.0, 4, 21, 55, 94)

mats = NeXLCore.compositionlibrary()
for (name, mat) in mats
    write(db, mat)
end

@testset "NeXLDatabase" begin
    # db = openNeXLDatabase(dbname)
    det3 = convert(BasicEDS, read(db, DBDetector, d3), 4096)
    @test isapprox(resolution(energy(n"Mn K-L3"), det3), 128.0, atol = 0.001)
    @test energy(1, det3) == 0.0
    @test length(NeXLSpectrum.visible(characteristic(n"Ca", ltransitions), det3)) == 0
    @test read(db,DBPerson,"dale.newbury@nist.gov").name == "Dale Newbury"

    k240 = read(db, Material, "K240")
    lab = read(db, DBLaboratory, l1)
    s1 = write(db, DBSample, l1, "SPI REP", "Rare Earth Phosphates")
    hsb = read(db,DBPerson,"hsb@gmail.com")
    testproj = read(db, DBProject, write(db, DBProject, "Tests", "Test projects", hsb))
    @test testproj.name == "Tests"
    @test testproj.description == "Test projects"
    @test testproj.createdBy.name == hsb.name
    proj = read(db, DBProject, write(db, DBProject, "REP", "Rare Earth Phosphates", hsb, testproj))
    @test proj.name == "REP"
    @test proj.description == "Rare Earth Phosphates"
    @test proj.parent.name == testproj.name
    for mat in ("CeP5O14", "LaP5O14", "NdP5O14", "PrP5O14", "SmP5O14", "YP5O14")
        midx = write(db, parse(Material, mat))
        sidx = write(
            db,
            DBSpectrum,
            d5,
            20.0e3,
            midx,
            ld2,
            s1,
            now(),
            mat * " standard",
            joinpath(joinpath(@__DIR__, "spectra"), mat * " std.msa"),
            "EMSA",
        )
        write(db, NeXLDatabase.DBProjectSpectrum, proj.pkey, sidx)
    end
    @testset "Base DB" begin
        @test isapprox(value(k240[n"Ba"]), 0.2687, atol = 0.000001)
        @test find(db, DBPerson, "jib@gmail.com") == ld2
        jib = read(db, DBPerson, find(db, DBPerson, "jib@gmail.com"))
        @test jib.name == "Jeanne I. Bottle"
        @test jib.email == "jib@gmail.com"
        @test jib.pkey == ld2
        @test find(db, DBPerson, "unknown@gmail.com") == -1
        @test find(db, DBPerson, "bqg@gmail.com") == ld1
        @test find(db, DBPerson, "nicholas.ritchie@nist.gov") == 1

        lab = read(db, DBLaboratory, l1)
        @test lab.pkey == l1
        @test lab.name == "OpenLab"
        @test lab.contact.pkey == find(db, DBPerson, "bqg@gmail.com")
    end

    @testset "Amy's GSR test" begin
        SQLite.transaction(db) do
            @test find(db, DBProject, 0, "Tests") == testproj.pkey
            write(db, DBPerson, "Amy", "amy@thelab.com")

            proj = write(db, DBProject, "GSR", "From Amy's GSR", read(db, DBPerson, "amy@thelab.com"), testproj)
            s2 = write(db, DBSample, l1, "Shooter #1 - Zero time", "A sample collected by the Boston Police")
            sidx = write(
                db,
                DBSpectrum,
                d5,
                20.0e3,
                1,
                ld1,
                s2,
                now(),
                "03272.tif",
                joinpath(joinpath(@__DIR__, "spectra"), "03272.tif"),
                "ASPEX",
            )
            write(db, NeXLDatabase.DBProjectSpectrum, proj, sidx)

            specs = read(db, DBProject, DBSpectrum, proj)
            @test length(specs) == 1
            sps = asa.(Spectrum, specs)
            @test sps[1][480] == 110.0

            for i in 1:100
                fn = tifffilename(i)
                sidx = write(
                    db,
                    DBSpectrum,
                    d5,
                    20.0e3,
                    1,
                    ld1,
                    s2,
                    now(),
                    fn,
                    joinpath(zip,fn),
                    "ASPEX",
                )
                write(db, NeXLDatabase.DBProjectSpectrum, proj, sidx)
            end
        end
        spec = asa(Spectrum, read(db, DBSpectrum, 95))
        @test spec[369] == 22.0
        @test max(spec[1:500]...) == 733.0
    end

    @testset "ADM-6005a" begin
        SQLite.transaction(db) do
            path = joinpath(@__DIR__, "ADM-6005a")
            project = write(db, DBProject, "ADM-6005a Test", "Description of ADM-6005a Test", read(db, DBPerson, "hsb@gmail.com"), testproj)
            det, person, e0, comp = 1, 2, 20.0e3, find(db, Material, "ADM6005a")
            fitspectra =
                write(db, NeXLDatabase.DBFitSpectra, project, det, [n"O", n"Al", n"Si", n"Ca", n"Ti", n"Zn", n"Ge"])
            sample = write(db, DBSample, 1, "ADM-6005a block", "ADM-6005a prepared by Eric Windsor")
            dt = DateTime(Date(2019, 7, 12), Time(9, 30, 0))
            for i in 1:15
                fn = "$path\\ADM-6005a_$(i).msa"
                spec = write(db, DBSpectrum, det, e0, comp, person, sample, dt, "ADM-6005a[$i]", fn, "EMSA")
                write(db, NeXLDatabase.DBFitSpectrum, fitspectra, spec)
            end
            block1 = write(db, DBSample, 1, "Standard Block C", "NIST Standard Block C")
            block2 = write(db, DBSample, 1, "High TC Block", "NIST High Temperature Superconductor Block")
            block3 = write(db, DBSample, 1, "Copper QC", "Copper QC Standard")
            for ref in ("Al", "Fe", "Ge", "Si", "SiO2", "Ti", "Zn")
                fn = "$path\\$(ref) std.msa"
                comp = find(db, Material, ref)
                if comp < 0
                    comp = write(db, parse(Material, ref))
                end
                sample = write(db, DBSample, block1, 1, ref, "$ref standard")
                spec = write(db, DBSpectrum, det, e0, comp, person, sample, dt, "$ref std", fn, "EMSA")
                ref = write(db, NeXLDatabase.DBReference, fitspectra, spec, [keys(parse(Material, ref))...])
            end
            for ref in ("CaF2",)
                fn = "$path\\$(ref) std.msa"
                comp = find(db, Material, ref)
                if comp < 0
                    comp = write(db, parse(Material, ref))
                end
                sample = write(db, DBSample, block2, 1, ref, "$ref standard")
                spec = write(db, DBSpectrum, det, e0, comp, person, sample, dt, "$ref std", fn, "EMSA")
                ref = write(db, NeXLDatabase.DBReference, fitspectra, spec, [keys(parse(Material, ref))...])
            end
        end

        fs = read(db, NeXLDatabase.DBFitSpectra, 1)
        @test fs.detector.vendor == "Bruker"
        @test fs.project.name == "ADM-6005a Test"
        @test !(n"Fe" in fs.elements)
        @test n"Ge" in fs.elements
        @test length(fs.fitspectrum) == 15
        @test length(fs.refspectrum) == 8
    end
end
@testset "Fit ADM from DB"  begin
    person=read(db,DBPerson,"dale.newbury@nist.gov")
    krp = read(db, DBProject, 0, "K-ratio Project")
    project = read(db, DBProject, write(db, DBProject, "Quant Test", "Description of Quant Test", person, krp))
    lab = findall(db,DBLaboratory, person)[1]
    sample = read(db, DBSample, write(db, DBSample, lab, "ADM-6005a block", "ADM-6005a prepared by Eric Windsor"))
    detector = findall(db,DBDetector,findall(db,DBInstrument, lab)[1])[1]
    unkComp = read(db,Material,"ADM6005a")

    blkC = read(db, DBSample, write(db, DBSample, lab, "Standard Block C", "NIST Standard Block C"))
    hiTC = read(db, DBSample, write(db, DBSample, lab, "High TC Block", "NIST High Temperature Superconductor Block"))
    e0 = 20.0e3

    path = joinpath(@__DIR__, "ADM-6005a")

    cfs = constructFitSpectra(db, project, sample, unkComp, detector, person, e0,
        [ joinpath(path,"ADM-6005a_$(i).msa") for i in 1:15 ], [
        # DBSample, Union{Material, Missing}, String, Float64, Vector{Element}}
        ( blkC, parse(Material,"Al"), joinpath(path,"Al std.msa"), e0, [ n"Al" ]),
        ( blkC, parse(Material,"Fe"), joinpath(path,"Fe std.msa"), e0, [ n"Fe" ]),
        ( blkC, parse(Material,"Ge"), joinpath(path,"Ge std.msa"), e0, [ n"Ge" ]),
        ( blkC, parse(Material,"Si"), joinpath(path,"Si std.msa"), e0, [ n"Si" ]),
        ( blkC, parse(Material,"SiO2"), joinpath(path,"SiO2 std.msa"), e0, [ n"Si", n"O", n"C" ]),
        ( blkC, parse(Material,"Ti"), joinpath(path,"Ti std.msa"), e0, [ n"Ti" ]),
        ( blkC, parse(Material,"Zn"), joinpath(path,"Zn std.msa"), e0, [ n"Zn" ]),
        ( hiTC, parse(Material,"CaF2"), joinpath(path,"CaF2 std.msa"), e0, [ n"Ca", n"F", n"C" ])
        ], [ n"C" ])
    unkcomp = read(db, Material, find(db,Material,"ADM6005a"))
    ffrs = NeXLSpectrum.fit(db, DBFitSpectra, cfs, unkcomp)

    @test isapprox(mean(value.(kratio(n"O K-L3", ffr) for ffr in ffrs)), 0.4896, rtol = 0.003)
    @test isapprox(mean(value.(kratio(n"Si K-L3", ffr) for ffr in ffrs)), 0.0214, atol = 0.013)
    @test isapprox(mean(value.(kratio(n"Al K-L3", ffr) for ffr in ffrs)), 0.0281, rtol = 0.004)
    @test isapprox(mean(value.(kratio(n"Ca K-L3", ffr) for ffr in ffrs)), 0.1211, rtol = 0.003)
    @test isapprox(mean(value.(kratio(n"Zn L3-M5", ffr) for ffr in ffrs)), 0.0700, rtol = 0.05)
    @test isapprox(mean(value.(kratio(n"Zn K-L3", ffr) for ffr in ffrs)), 0.1115, atol = 0.0005)
    @test isapprox(mean(value.(kratio(n"Zn K-M3", ffr) for ffr in ffrs)), 0.1197, atol = 0.0002)
    @test isapprox(mean(value.(kratio(n"Ti L3-M3", ffr) for ffr in ffrs)), 0.0541, atol = 0.22)
    @test isapprox(mean(value.(kratio(n"Ti K-L3", ffr) for ffr in ffrs)), 0.064, atol = 0.001)
    @test isapprox(mean(value.(kratio(n"Ti K-M3", ffr) for ffr in ffrs)), 0.064, rtol = 0.06)
    @test isapprox(mean(value.(kratio(n"Ge L3-M5", ffr) for ffr in ffrs)), 0.1789, rtol = 0.01)
    @test isapprox(mean(value.(kratio(n"Ge K-L3", ffr) for ffr in ffrs)), 0.2628, atol = 0.001)
    @test isapprox(mean(value.(kratio(n"Ge K-M3", ffr) for ffr in ffrs)), 0.279, atol = 0.011)
end
