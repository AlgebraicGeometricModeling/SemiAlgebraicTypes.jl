using Documenter, SemiAlgebraicTypes

Expl = []; 
Code = ["basic.md", "mesh.md", "attributes.md"];

makedocs(
         sitename = "SemiAlgebraicTypes.jl",
         authors = "B. Mourrain",
         modules = [SemiAlgebraicTypes],
         build = "SemiAlgebraicTypes.jl/docs",
         source = "mrkd",
         pages = Any[
                     "Home" => "index.md",
#                     "Example" => Expl,
                     "SemiAlgebraic types" => Code
                     ],
         repo = "https://github.com/AlgebraicGeometricModeling/SemiAlgebraicTypes.jl",
         doctest = false
         )

deploydocs(
#    root = "docs",
    repo = "github.com/AlgebraicGeometricModeling/SemiAlgebraicTypes.jl",
    target = "build",
#    devbranch = "master",
    push_preview = true
)

