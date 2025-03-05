module SemiAlgebraicTypes

using LinearAlgebra

SAT = Dict{Symbol, Any}( :pkgdir => dirname(dirname(pathof(SemiAlgebraicTypes))) )

include("shapes.jl")
include("mesh.jl")
include("hmesh.jl")
include("tmesh.jl")
include("bspline.jl")
include("parametric.jl")

include("offdata.jl")
include("axldata.jl")

include("color.jl")

end
