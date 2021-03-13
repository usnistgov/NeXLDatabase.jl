projectdir() = "C:\\Users\\nritchie\\Documents\\DrWatson\\K-Ratio Project"

using NeXLDatabase
using DataFrames
using Gadfly
using Weave

krdPath = joinpath(projectdir(), "data","exp_raw")
krdb = joinpath(projectdir(), "Data", "exp_pro", "kratio.db")
db = openNeXLDatabase(krdb)
if false
  dale = read(db,DBPerson,"dale.newbury@nist.gov")
  nicholas = read(db, DBPerson, "nicholas.ritchie@nist.gov")
  analyst=dale
  krp = read(db, DBProject, 0, "K-ratio Project")
  lab = findall(db,DBLaboratory, analyst)[1]
  jeol = read(db, DBInstrument, write(db, DBInstrument, lab, "JEOL", "JXA-8500F", "217 D113"))
  tescan = read(db, DBInstrument, write(db, DBInstrument, lab, "TESCAN", "MIRA-3", "217 F101"))

  brukersingle = read(db, DBDetector, write(db, DBDetector, jeol, "Bruker", "XFlash 6|30", "Bruker Single", 128.9, 121, -483.9, 5.0163, z(n"Be"), z(n"Sc"), z(n"Sn"), z(n"Pu")))
  brukerquad = read(db, DBDetector, write(db, DBDetector, jeol, "Bruker", "XFlash QUAD 5040", "Bruker Quad", 131.0, 121, -478.0, 5.003, 4, 21, 55, 94))
  for ii in 0:3
      write(db, DBDetector, tescan, "Pulsetor", "Torrent", "Torrent $ii", 131.0, 20, 0.0, 10.0, 4, 21, 55, 94)
  end
  write(db, DBDetector, tescan, "Pulsetor", "Torrent", "Torrent (combined)", 131.0, 20, 0.0, 10.0, 4, 21, 55, 94)
  pulsetor = findall(db, DBDetector, tescan, vendor="Pulsetor",model="Torrent")

  blockC = read(db, DBSample, write(db, DBSample, lab, "Standard Mount C", "NIST's Standard Mount C - Mostly pure elements"))
  blockElm = read(db, DBSample, write(db, DBSample, lab, "Element Mount I", "NIST's Element Mount I - Mostly pure elements"))
  blockElm2 = read(db, DBSample, write(db, DBSample, lab, "Element Mount II", "NIST's Element Mount I - Mostly pure elements"))
  blockHiTC = read(db, DBSample, write(db, DBSample, lab, "HighTC Block", "NIST's High Temperature Superconductor Block"))
  blockChMixed = read(db, DBSample, write(db, DBSample, lab, "Chuck's Mixed", "NIST's Chuck's Mixed Standards Block"))
  blockGM3 = read(db, DBSample, write(db, DBSample, lab, "Glass Mount III", "NIST's Glass Mount III"))
  blockUnk = read(db, DBSample, write(db, DBSample, lab, "Unknown", "Unknown"))
  blockFe3Si = read(db, DBSample, write(db, DBSample, lab, "??Fe3Si??", "SRM-483 block in ???"))
  blockAuAgCu = read(db, DBSample, write(db, DBSample, lab, "SRM-481 & 482 block", "SRM-481 & 482 block in ???"))
  alphaAesar = read(db, DBSample, write(db, DBSample, lab, "Alfa-Aesar Sample", "Sourced from Alfa-Aesar"))
  maurine = read(db, DBSample, write(db, DBSample, lab, "Maureen William's Sample", "Co alloys"))
  colby = read(db, DBSample, write(db, DBSample, lab, "Colby's Fe-Cr alloys", "Fe-Cr alloys"))
  geller583 = read(db, DBSample, write(db, DBSample, lab, "Geller 583","Geller Low-Z APA Mount"))
  geller588 = read(db, DBSample, write(db, DBSample, lab, "Geller 588","Geller Higher-Z APA Mount"))
  mmm1 = read(db, DBSample, write(db, DBSample, lab, "Mengason Mineral Mount 1", "Mengason Mineral Mount 1"))
  mmm2 = read(db, DBSample, write(db, DBSample, lab, "Mengason Mineral Mount 2", "Mengason Mineral Mount 2"))

  carbonCoating, noCoating= [ n"C" ], Element[]

  sulfides10=joinpath(krdPath,"Sulfides_NewBruker","10_keV_Sulfides")
  project = read(db, DBProject, write(db, DBProject, "Sulfides", "Sulfides - CuS, FeS, FeS2, CdS, PbS, ZnS", analyst, krp))
  sample = blockC
  e0 = 10.0e3

  unks = [
    joinpath(sulfides10,"EDITED_FeS_StdC_10keV","FeS_StdC_1_10kV10nA130kHz_62kHz12DT_100s.msa"),
    joinpath(sulfides10,"EDITED_FeS_StdC_10keV","FeS_StdC_2_10kV10nA130kHz_62kHz12DT_100s.msa"),
    joinpath(sulfides10,"EDITED_FeS_StdC_10keV","FeS_StdC_3_10kV10nA130kHz_62kHz12DT_100s.msa"),
    joinpath(sulfides10,"EDITED_FeS_StdC_10keV","FeS_StdC_4_10kV10nA130kHz_62kHz12DT_100s.msa"),
    joinpath(sulfides10,"EDITED_FeS_StdC_10keV","FeS_StdC_5_10kV10nA130kHz_62kHz12DT_100s.msa"),
    joinpath(sulfides10,"EDITED_FeS_StdC_10keV","FeS_StdC_6_10kV10nA130kHz_62kHz12DT_100s.msa"),
    joinpath(sulfides10,"EDITED_FeS_StdC_10keV","FeS_StdC_7_10kV10nA130kHz_62kHz12DT_100s.msa"),
  ]

  stds = [
    #(blockChMixed, mat"CdSe", joinpath(sulfides10,"EDITED_Standards_10keV","CdSe_ChMxd_10kV10nA130kHz_300s.msa"), e0, noCoating ),
    #(blockChMixed, mat"CdS", joinpath(sulfides10,"EDITED_Standards_10keV","CdS_ChMxd_10kV10nA130kHz_700s.msa"), e0, noCoating ),
    #(blockChMixed, mat"Cd", joinpath(sulfides10,"EDITED_Standards_10keV","Cd_ChMxd_10kV10nA130kHz_300s.msa"), e0, noCoating ),
    #(blockC, mat"Cd", joinpath(sulfides10,"EDITED_Standards_10keV","Cd_StdC_10kV10nA130kHz_300s.msa"), e0, noCoating ),
    #(blockChMixed, mat"CuS", joinpath(sulfides10,"EDITED_Standards_10keV","CuS_ChMxd_10kV10nA130kHz_700s.msa"), e0, noCoating ),
    #(blockC, mat"Cu", joinpath(sulfides10,"EDITED_Standards_10keV","Cu_StdC_10kV10nA130kHz_300s.msa"), e0, noCoating ),
    #(blockC, mat"C", joinpath(sulfides10,"EDITED_Standards_10keV","C_StdC_10kV10nA130kHz_53kHz10DT_200s.msa"), e0, noCoating ),
    #(blockChMixed, mat"CdS", joinpath(sulfides10,"EDITED_Standards_10keV","EDITED_CdS_ChMxd_1_10kV10nA130kHz_78kHz15DT_100s.msa"), e0, noCoating ),
    (blockChMixed, mat"FeS2", joinpath(sulfides10,"EDITED_Standards_10keV","FeS2_ChMxd_10kV10nA130kHz_700s.msa"), e0, noCoating ),
    (blockChMixed, mat"Fe", joinpath(sulfides10,"EDITED_Standards_10keV","Fe_ChMxd_10kV10nA130kHz_300s.msa"), e0, noCoating ),
    #(blockC, mat"Fe," joinpath(sulfides10,"EDITED_Standards_10keV","Fe_StdC_10kV10nA130kHz_300s.msa"), e0, noCoating ),
    #(blockC, mat"MgO", joinpath(sulfides10,"EDITED_Standards_10keV","MgO_StdC_10kV10nA130kHz_81kHz15DT_100s.msa"), e0, noCoating ),
    #(blockC, mat"PbSe", joinpath(sulfides10,"EDITED_Standards_10keV","PbSe_StdC_10kV10nA130kHz_300s.msa"), e0, noCoating ),
    #(blockChMixed, mat"PbTe", joinpath(sulfides10,"EDITED_Standards_10keV","PbTe_ChMxd_10kV10nA130kHz_300s.msa"), e0, noCoating ),
    #(blockC, mat"Se", joinpath(sulfides10,"EDITED_Standards_10keV","Se_StdC_10kV10nA130kHz_107kHz20DT_100s.msa"), e0, noCoating ),
    #(blockChMixed, mat"Te", joinpath(sulfides10,"EDITED_Standards_10keV","Te_ChMxd_10kV10nA130kHz_74kHz14DT_100s.msa"), e0, noCoating ),
    #(blockC, mat"Zn", joinpath(sulfides10,"EDITED_Standards_10keV","Zn_StdC_10kV10nA130kHz_300s.msa"), e0, noCoating ),
  ]

  cfs = write(db, DBCampaign, project, sample, unkComp, brukersingle, analyst, e0, unks, stds, noCoating)
else
  cfs = 85
end

unkComp = parse(Material, "FeS", pedigree="Stoichiometric")
ffrs = fit_spectrum(db, DBCampaign, cfs, unkComp)
display(asa(DataFrame, ffrs))
display(plot(ffrs[1]))
#display(plot(loadspectrum.(unks)...,klms=[ n"C", keys(unkComp)... ], xmax=10.0e3))