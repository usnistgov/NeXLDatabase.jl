### A Pluto.jl notebook ###
# v0.12.4

using Markdown
using InteractiveUtils

# This Pluto notebook uses @bind for interactivity. When running this notebook outside of Pluto, the following 'mock version' of @bind gives bound variables a default value (instead of an error).
macro bind(def, element)
    quote
        local el = $(esc(element))
        global $(esc(def)) = Core.applicable(Base.get, el) ? Base.get(el) : missing
        el
    end
end

# ╔═╡ 2360bd70-1a15-11eb-3b28-75fdf85c0706
using NeXLDatabase

# ╔═╡ 290a7a40-1a15-11eb-338e-1d2c5e513ab3
using Gadfly, DataFrames, PlutoUI

# ╔═╡ bede52a0-1a27-11eb-1206-2bd005ea4d01
using SQLite

# ╔═╡ 30233060-1a15-11eb-2d1f-8b7537f66d45
db=openNeXLDatabase("C:\\Users\\nritchie\\Documents\\DrWatson\\K-Ratio Project\\data\\exp_pro\\kratio.db")

# ╔═╡ 7cfccdb0-1a15-11eb-37b7-4f1f1aff8f2f
begin
	labs = findall(db, DBLaboratory)
	md"""
	#### Laboratories
	Select a lab: $(@bind lab Select([ repr(i) => repr(lab) for (i, lab) in enumerate(labs) ]))
	"""
end

# ╔═╡ 3bded950-1a23-11eb-3d86-c1d125393e99
begin
	thelab = labs[parse(Int,lab)]
	members = findall(db, DBPerson, thelab)
	md"""
	#### Lab Members
	Select a lab member: $(@bind lmi Select([ repr(i) => person.name for (i, person) in enumerate(members) ]))
	"""
end

# ╔═╡ c5eb0000-1a15-11eb-0f46-99d1ca2092f6
begin
	theperson = members[parse(Int,lmi)]
	projects = findall(db, DBProject, theperson)
	md"""
	#### Projects
	Select a project: $(@bind pidx Select([ repr(i) => repr(proj) for (i, proj) in enumerate(projects) ]))
	"""
end

# ╔═╡ 2d6bb0b0-1a45-11eb-2233-c92381d65e13


# ╔═╡ c602c890-1a27-11eb-19fc-c79cbf0026c1
begin
	theproject = projects[parse(Int,pidx)] 
	fspecs = findall(db, DBFitSpectra, project=theproject)
	asa(DataFrame, fspecs) 
end

# ╔═╡ Cell order:
# ╟─2360bd70-1a15-11eb-3b28-75fdf85c0706
# ╟─290a7a40-1a15-11eb-338e-1d2c5e513ab3
# ╟─30233060-1a15-11eb-2d1f-8b7537f66d45
# ╟─7cfccdb0-1a15-11eb-37b7-4f1f1aff8f2f
# ╟─3bded950-1a23-11eb-3d86-c1d125393e99
# ╟─c5eb0000-1a15-11eb-0f46-99d1ca2092f6
# ╟─bede52a0-1a27-11eb-1206-2bd005ea4d01
# ╟─2d6bb0b0-1a45-11eb-2233-c92381d65e13
# ╟─c602c890-1a27-11eb-19fc-c79cbf0026c1
