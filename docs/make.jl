using Documenter, SemiAlgebraicTypes

Expl = []; 
Code = ["basic.md", "mesh.md", "parametric.md", "splines.md"];

makedocs(
         sitename = "SemiAlgebraicTypes.jl",
         authors = "B. Mourrain",
         modules = [SemiAlgebraicTypes],
         build = "SemiAlgebraicTypes.jl/docs",
         source = "mrkd",
         pages = Any[
             "Home" => "index.md",
#                     "Example" => Expl,
             "SemiAlgebraic types" => Code,
             "Attributes" => "attributes.md",
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

