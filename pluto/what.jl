using DrWatson

@quickactivate "K-Ratio Project"
using NeXLDatabase
using Gadfly, DataFrames, PlutoUI, CSV
db=openNeXLDatabase(datadir("exp_pro","kratio.db"))

pkeys =  ( 84, 85, 90, 91, 96, 97 )

krs = mapreduce(fs->findall(db, DBKRatio, campaign=fs), append!, pkeys)

Gadfly.plot(krs)