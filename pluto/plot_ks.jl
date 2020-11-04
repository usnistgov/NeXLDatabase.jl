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

# ╔═╡ c14208c0-1851-11eb-35fb-c98e40f3aff2
using NeXLDatabase

# ╔═╡ f6fee690-1851-11eb-3c4c-39b825e337e2
using Gadfly, DataFrames, PlutoUI

# ╔═╡ 3742ed50-1852-11eb-01e3-5b27d6c85250
db=openNeXLDatabase("C:\\Users\\nritchie\\Documents\\DrWatson\\K-Ratio Project\\data\\exp_pro\\kratio.db")

# ╔═╡ e793f370-1852-11eb-24b6-05fa57c3a3c6
md"""
Select an element or elements: $(@bind els MultiSelect(map(el->symbol(el),elements[1:94]),default=["Al"]))
"""

# ╔═╡ 78885a50-1859-11eb-0b6c-3368b717d267
md"""
Specify the minimum k-ratio: $(@bind mink NumberField(0.00 : 0.01 : 1.0; default=0.1))
"""

# ╔═╡ a51b0a40-1921-11eb-2c1c-ab31e48e7846
allkrs = mapreduce(el->findall(db, DBKRatio, elm=parse(Element,el), mink=mink), append!, els)

# ╔═╡ 22f61d10-185a-11eb-2c53-85f7ef0fb78a
md"""
Select which set of measurements to display:

$(@bind krsnames MultiSelect(sort(unique(map(kr->NeXLDatabase.krname(kr), allkrs)))))
"""

# ╔═╡ 2a8bd5f0-185b-11eb-0b96-8592774730a0
begin 
	krs = filter(kr->NeXLDatabase.krname(kr) in krsnames, allkrs)
	if length(krs)>0
		plot(krs)
	else
		md"No k-ratios have been selected"
	end
end

# ╔═╡ cb991c00-1888-11eb-02fb-b33a153473dc
asa(DataFrame, [ read(db, DBFitSpectra, kr.fitspectra) for kr in krs])

# ╔═╡ 6185fa20-19d9-11eb-04d3-3132221ca798
begin
	if length(krs)>0
		plot(krs, style=:XY)
	else
		md"No k-ratios have been selected"
	end
end

# ╔═╡ Cell order:
# ╠═c14208c0-1851-11eb-35fb-c98e40f3aff2
# ╠═f6fee690-1851-11eb-3c4c-39b825e337e2
# ╟─3742ed50-1852-11eb-01e3-5b27d6c85250
# ╟─e793f370-1852-11eb-24b6-05fa57c3a3c6
# ╟─78885a50-1859-11eb-0b6c-3368b717d267
# ╟─a51b0a40-1921-11eb-2c1c-ab31e48e7846
# ╟─22f61d10-185a-11eb-2c53-85f7ef0fb78a
# ╟─2a8bd5f0-185b-11eb-0b96-8592774730a0
# ╟─cb991c00-1888-11eb-02fb-b33a153473dc
# ╟─6185fa20-19d9-11eb-04d3-3132221ca798
