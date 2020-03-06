using Test
using NeXLDatabase
using NeXLSpectrum

@testset begin

    db = openNeXLDatabase(tempname())
    write(db, DBPerson, "H. Son Beetle","hsb@gmail.com")
    ld1=write(db, DBPerson, "Harry Q. Grenfeld","hqg@gmail.com")
    ld2=write(db, DBPerson, "Jeanne I. Bottle","jib@gmail.com")
    l1=write(db, DBLaboratory, "OpenLab", ld1)
    l2=write(db, DBLaboratory, "ClosedLab", ld2)
    for (name, mat) in compositionlibrary()
        write(db,mat)
    end
    i1=write(db, DBInstrument,l1,"JEOL","JXA-7001","H103")
    i2=write(db, DBInstrument,l1,"TESCAN","MIRA3","H119")
    i3=write(db, DBInstrument,l2,"Hitachi","SU-2000","Gr19")
    i4=write(db, DBInstrument,l2,"Cameca","SX-5","Gr22")
    d1=write(db, DBDetector, i1, "Bruker","Esprit 6|30","30 mm² SDD")
    d2=write(db, DBDetector, i2, "Oxford","XMAX 100","100 mm² SDD")
    d3=write(db, DBDetector, i3, "EDAX","Octane","30 mm² SDD")
    d4=write(db, DBDetector, i4, "Thermo","UltraDry","100 mm² SDD")

    # write(db, DBArtifact, )
end
