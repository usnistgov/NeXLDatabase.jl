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

# ╔═╡ 30233060-1a15-11eb-2d1f-8b7537f66d45
db=openNeXLDatabase("C:\\Users\\nritchie\\Documents\\DrWatson\\K-Ratio Project\\data\\exp_pro\\kratio.db")

# ╔═╡ 7cfccdb0-1a15-11eb-37b7-4f1f1aff8f2f
begin
	labs = findall(db, DBLaboratory)
	md"""
	Select a lab: $(@bind lab Select([ repr(i) => repr(lab) for (i, lab) in enumerate(labs) ]))
	"""
end

# ╔═╡ ee29aa10-1a17-11eb-3fac-5166acfccd86
md"""
#### Lab Members
"""

# ╔═╡ a391aa40-1a15-11eb-3bd4-45eeff75d6e3
begin 
	thelab = labs[parse(Int,lab)]
	members = findall(db, DBPerson, thelab)
	function NeXLUncertainties.asa(::Type{DataFrame}, people::AbstractArray{DBPerson})
		return DataFrame(
			PKey = [ person.pkey for person in people ],
			Name = [ person.name for person in people ],
			EMail = [ person.email for person in people ]
		)
	end
	asa(DataFrame, members)
end

# ╔═╡ fc72e40e-1a17-11eb-2f3c-038a1f5b98d7
md"""
#### Lab Instruments
"""

# ╔═╡ c5eb0000-1a15-11eb-0f46-99d1ca2092f6
begin
	instruments = findall(db, DBInstrument, thelab)
	md"""
	Select a instrument: $(@bind instidx Select([ repr(i) => repr(inst) for (i, inst) in enumerate(instruments) ]))
	"""
end

# ╔═╡ 063a1862-1a18-11eb-0424-ebdcc6ccc526
md"""
#### Detectors
"""

# ╔═╡ eb7faa9e-1a15-11eb-23af-0ba535efb5f6
begin
	theinstrument = instruments[parse(Int,instidx)]
	detectors = findall(db, DBDetector, theinstrument)
	md"""
	Select a detector: $(@bind detidx Select([ repr(i) => repr(det) for (i, det) in enumerate(detectors) ]))
	"""
end

# ╔═╡ 150e5450-1a18-11eb-1f6d-8fe22b72fa94
begin
	thedetector = detectors[parse(Int,detidx)]
	asa(DataFrame,thedetector)
end

# ╔═╡ Cell order:
# ╠═2360bd70-1a15-11eb-3b28-75fdf85c0706
# ╠═290a7a40-1a15-11eb-338e-1d2c5e513ab3
# ╟─30233060-1a15-11eb-2d1f-8b7537f66d45
# ╟─7cfccdb0-1a15-11eb-37b7-4f1f1aff8f2f
# ╟─ee29aa10-1a17-11eb-3fac-5166acfccd86
# ╟─a391aa40-1a15-11eb-3bd4-45eeff75d6e3
# ╟─fc72e40e-1a17-11eb-2f3c-038a1f5b98d7
# ╟─c5eb0000-1a15-11eb-0f46-99d1ca2092f6
# ╟─063a1862-1a18-11eb-0424-ebdcc6ccc526
# ╟─eb7faa9e-1a15-11eb-23af-0ba535efb5f6
# ╟─150e5450-1a18-11eb-1f6d-8fe22b72fa94
