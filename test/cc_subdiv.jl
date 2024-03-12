push!(LOAD_PATH, "/Users/mourrain/Julia")
using SemiAlgebraicTypes
include("../../G1Splines.jl/src/G1Splines.jl")

m = offread("../../G1splines.jl/data/cube_origin.off")

hm = hmesh(m)

cc_subdivide!(hm)
hm
