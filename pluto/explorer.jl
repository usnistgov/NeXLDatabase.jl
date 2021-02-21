### A Pluto.jl notebook ###
# v0.12.18

using Markdown
using InteractiveUtils

# ╔═╡ 004a9900-576e-11eb-0a75-550da1a57e0d
begin
	using DrWatson

	@quickactivate "K-Ratio Project"
	using NeXLDatabase
	using Gadfly, DataFrames, PlutoUI, CSV
	db=openNeXLDatabase(datadir("exp_pro","kratio.db"))
	md"""
	# k-ratio Database Explorer
	Utilities for exploring the k-ratio database.
	"""
end

# ╔═╡ 6f8e06d0-576e-11eb-3dd5-9fc72c66f2c0


# ╔═╡ Cell order:
# ╠═004a9900-576e-11eb-0a75-550da1a57e0d
# ╠═6f8e06d0-576e-11eb-3dd5-9fc72c66f2c0
