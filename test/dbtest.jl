using Test
using NeXLCore
using NeXLSpectrum
using NeXLDatabase
using SQLite
using Dates

dbname = ":memory:" # tempname()
db = openNeXLDatabase(dbname)
@testset "NeXLDatabase" begin
    # db = openNeXLDatabase(dbname)
    write(db, DBPerson, "Harvey Sun Beetle", "hsb@gmail.com")
    ld1 = write(db, DBPerson, "Butterbean Q. Grenfeld, III", "bqg@gmail.com")
    ld2 = write(db, DBPerson, "Jeanne I. Bottle", "jib@gmail.com")

    l1 = write(db, DBLaboratory, "OpenLab", read(db, DBPerson, ld1))
    l2 = write(db, DBLaboratory, "ClosedLab", read(db, DBPerson, ld2))

    write(db, DBMember, l1, 1)
    write(db, DBMember, l2, 2)

    i1 = write(db, DBInstrument, l1, "JEOL", "JXA-7001", "H103")
    i2 = write(db, DBInstrument, l1, "TESCAN", "MIRA3", "H119")
    i3 = write(db, DBInstrument, l2, "Hitachi", "SU-2000", "Gr19")
    i4 = write(db, DBInstrument, l2, "Cameca", "SX-5", "Gr22")

    d1 = write(db, DBDetector, i1, "Bruker", "Esprit 6|30", "30 mm² SDD")
    d2 = write(db, DBDetector, i2, "Oxford", "XMAX 100", "100 mm² SDD")
    d3 = write(db, DBDetector, i3, "EDAX", "Octane", "30 mm² SDD")
    d4 = write(db, DBDetector, i4, "Thermo", "UltraDry", "100 mm² SDD")
    d5 = write(db, DBDetector, i2, "Pulsetor", "Torrent", "4 × 30 mm² SDD")

    mats = NeXLCore.compositionlibrary()
    for (name, mat) in mats
        write(db, mat)
    end

    k240 = read(db, Material, "K240")
    lab = read(db, DBLaboratory, l1)
    s1 = write(db, DBSample, l1, "SPI REP", "Rare Earth Phosphates")
    testproj = write(db, DBProject, "Tests", "Test projects")
    proj = write(db, DBProject, "REP", "Rare Earth Phosphates", testproj)
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
            joinpath(joinpath(@__DIR__,"spectra"), mat * " std.msa"),
            "EMSA",
        )
        write(db, NeXLDatabase.DBProjectSpectrum, proj, sidx)
    end
    @testset "Base DB" begin
        @test isapprox(value(k240[n"Ba"]), 0.2687, atol = 0.000001)
        @test find(db, DBPerson, "jib@gmail.com") == ld2
        jib = read(db, DBPerson, find(db, DBPerson, "jib@gmail.com"))
        @test jib.name=="Jeanne I. Bottle"
        @test jib.email=="jib@gmail.com"
        @test jib.pkey==ld2
        @test find(db, DBPerson, "unknown@gmail.com") == -1
        @test find(db, DBPerson, "bqg@gmail.com") == ld1
        @test find(db, DBPerson, "nicholas.ritchie@nist.gov") == 1

        lab = read(db, DBLaboratory, l1)
        @test lab.pkey==l1
        @test lab.name=="OpenLab"
        @test lab.contact.pkey==find(db, DBPerson, "bqg@gmail.com")
    end

    @testset "Amy's GSR test" begin
        SQLite.transaction(db) do
            @test testproj == find(db, DBProject, 0, "Tests")
            proj = write(db, DBProject, "GSR", "From Amy's GSR", testproj)
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
                joinpath(joinpath(@__DIR__,"spectra"), "03272.tif"),
                "ASPEX",
            )
            write(db, NeXLDatabase.DBProjectSpectrum, proj, sidx)

            specs = read(db, DBProject, DBSpectrum, proj)
            @test length(specs)==1
            sps=convert.(Spectrum, specs)
            @test sps[1][480]==110.0

            function tifffilename(i)
               res = "$i.tif"
               return repeat('0',max(0,9-length(res)))*res
            end

            for i in 10:1000
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
                    joinpath("c:\\Users\\nritchie\\Desktop\\Amy's GSR\\Shooter #1 - Zero time\\APA\\Analysis 2019-07-17 10.58.57.-0400\\Mag0", fn),
                    "ASPEX",
                )
                write(db, NeXLDatabase.DBProjectSpectrum, proj, sidx)
            end
        end
        spec = convert(Spectrum, read(db, DBSpectrum, 200))
        @test spec[369]==465.0
        @test max(spec[1:500]...)==567.0
    end

    #using Gadfly
    #plot(spec, klms=[n"Ca",n"O",n"C"],xmax=10.0e3)
    @testset "ADM-6005a" begin
        SQLite.transaction(db) do
            path = joinpath(@__DIR__,"ADM-6005a")
            project = write(db, DBProject, "ADM-6005a Test", "Description of ADM-6005a Test", testproj)
            det, person, e0, comp = 1, 2, 20.0e3, find(db, Material, "ADM6005a")
            fitspectra=write(db, NeXLDatabase.DBFitSpectra, project, det, [n"O",n"Al",n"Si",n"Ca",n"Ti",n"Zn",n"Ge"])
            sample = write(db, DBSample, 1, "ADM-6005a block","ADM-6005a prepared by Eric Windsor")
            dt=DateTime(Date(2019,7,12),Time(9,30,0))
            for i in 1:15
                fn = "$path\\ADM-6005a_$(i).msa"
                spec = write(db, DBSpectrum, det, e0, comp, person, sample, dt, "ADM-6005a[$i]", fn, "EMSA")
                write(db, NeXLDatabase.DBFitSpectrum, fitspectra, spec)
            end
            block1 = write(db, DBSample, 1, "Standard Block C","NIST Standard Block C")
            block2 = write(db, DBSample, 1, "High TC Block","NIST High Temperature Superconductor Block")
            block3 = write(db, DBSample, 1, "Copper QC","Copper QC Standard")
            for ref in ( "Al", "Al2O3", "C", "Fe", "Ge", "K411", "K412", "MgO", "Si", "SiO2", "Ti", "Zn", "Cu" )
                fn = "$path\\$(ref)_StdC.msa"
                comp = find(db, Material, ref)
                if comp<0
                    comp = write(db, parse(Material, ref))
                end
                sample = write(db, DBSample, block1, 1, ref,"$ref standard")
                spec = write(db, DBSpectrum, det, e0, comp, person, sample, dt, "$ref std", fn, "EMSA")
                ref = write(db, NeXLDatabase.DBReference, fitspectra, spec, [keys(parse(Material,ref))...])
            end
            for ref in ( "CaF2", )
                fn = "$path\\$(ref)_HiTc.msa"
                comp = find(db, Material, ref)
                if comp<0
                    comp = write(db, parse(Material, ref))
                end
                sample = write(db, DBSample, block2, 1, ref,"$ref standard")
                spec = write(db, DBSpectrum, det, e0, comp, person, sample, dt, "$ref std", fn, "EMSA")
                ref = write(db, NeXLDatabase.DBReference, fitspectra, spec, [keys(parse(Material,ref))...])
            end
        end

        fs = read(db, NeXLDatabase.DBFitSpectra, 1)
        @test fs.detector.vendor == "Bruker"
        @test fs.project.name == "ADM-6005a Test"
        @test !(n"Fe" in fs.elements)
        @test n"Ge" in fs.elements
        @test length(fs.fitspectrum)==15
        @test length(fs.refspectrum)==14
    end
end

pickaref(refs) = refs[1]

fs = read(db, NeXLDatabase.DBFitSpectra, 1)
unks = NeXLDatabase.unknowns(fs)
det = matching(unks[1], 132.0)
ff = buildfilter(det)

e0 = NeXLSpectrum.sameproperty(unks, :BeamEnergy)
frs = FilteredReference[]
for elm in fs.elements
    spec = pickaref(NeXLDatabase.reference(fs, elm))
    ref = pickaref(NeXLDatabase.dbreference(fs, elm))
    spec = convert(Spectrum, ref.spectrum)
    for cxrl in NeXLDatabase.charXRayLabels(ref, elm, det, 1.0e-4, e0)
        push!(frs, filter(cxrl, ff, 1.0/dose(spec)))
    end
end

fr = fit(unks[1], ff, frs)
