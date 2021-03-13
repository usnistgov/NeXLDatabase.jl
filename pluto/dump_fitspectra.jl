### A Pluto.jl notebook ###
# v0.12.18

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

# ╔═╡ ca82b4c2-1a0e-11eb-3d58-e113dc5f9dda
using NeXLDatabase

# ╔═╡ f5392780-1a0e-11eb-16f1-a16ea6f04c43
using Gadfly, DataFrames, PlutoUI

# ╔═╡ e3ad5030-1a0f-11eb-3290-61173ae4e0ae
db=openNeXLDatabase("C:\\Users\\nritchie\\Documents\\DrWatson\\K-Ratio Project\\data\\exp_pro\\kratio.db")

# ╔═╡ 5093b0a0-1a0f-11eb-2e93-316f2134efd8
md"""
Specify which set of spectra to load: $(@bind pkey NumberField(1:10000, default=1))
"""

# ╔═╡ 9af18310-1a10-11eb-204f-7df12505577e
md"""
#### Meta-Data
"""

# ╔═╡ 18221310-1a0f-11eb-39f2-7b9c81700306
begin
	fs = read(db, DBCampaign, pkey)
	asa(DataFrame, fs)
end

# ╔═╡ 3a9982b0-1a10-11eb-3d1d-2f0a47c5287a
md"""
#### Unknown Spectra
"""

# ╔═╡ 31b6e200-1a10-11eb-3ef3-ede36488bf5b
asa(DataFrame, fs.fitspectrum)

# ╔═╡ aad1b0c0-1a10-11eb-2e1c-3787ec7e2806
begin
	set_default_plot_size(8inch,3inch)
	plot(measured(fs), norm=ScaleDose(), klms=elements(fs))
end

# ╔═╡ 4ad19460-1a10-11eb-0a23-5b97820a5af1
md"""
#### Reference Spectra
"""

# ╔═╡ 1d393760-1a10-11eb-29bf-69dbc16658cd
asa(DataFrame, fs.refspectrum)

# ╔═╡ b1aea0f0-1a11-11eb-36a4-6d433b7c97d8
begin
	references2(fbfs::DBCampaign, elm::Element)::Vector{Spectrum} = map(ref->asa(Spectrum,ref), dbreferences(fbfs, elm))
	set_default_plot_size(8inch,3inch)
	refs = mapreduce(el->references2(fs,el), append!, elements(fs))
	plot(refs, norm=ScaleDose(), klms=elements(fs))
end

# ╔═╡ Cell order:
# ╠═ca82b4c2-1a0e-11eb-3d58-e113dc5f9dda
# ╠═f5392780-1a0e-11eb-16f1-a16ea6f04c43
# ╠═e3ad5030-1a0f-11eb-3290-61173ae4e0ae
# ╟─5093b0a0-1a0f-11eb-2e93-316f2134efd8
# ╟─9af18310-1a10-11eb-204f-7df12505577e
# ╟─18221310-1a0f-11eb-39f2-7b9c81700306
# ╟─3a9982b0-1a10-11eb-3d1d-2f0a47c5287a
# ╟─31b6e200-1a10-11eb-3ef3-ede36488bf5b
# ╟─aad1b0c0-1a10-11eb-2e1c-3787ec7e2806
# ╟─4ad19460-1a10-11eb-0a23-5b97820a5af1
# ╟─1d393760-1a10-11eb-29bf-69dbc16658cd
# ╟─b1aea0f0-1a11-11eb-36a4-6d433b7c97d8
