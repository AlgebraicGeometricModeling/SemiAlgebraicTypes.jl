using Documenter, SemiAlgebraicTypes

Expl = []; 
Code = ["code.md", "mesh.md"];

makedocs(
         sitename = "SemiAlgebraicTypes.jl",
         authors = "B. Mourrain",
         modules = [SemiAlgebraicTypes],
         build = "html",
         source = "mrkd",
         pages = Any[
                     "Home" => "index.md",
                     "Example" => Expl,
                     "SemiAlgebraic types" => Code
                     ],
         repo = "https://github.com/AlgebraicGeometricModeling/SemiAlgebraicTypes.jl",
         doctest = false
         )

deploydocs(
    root = "docs",
    repo = "github.com/AlgebraicGeometricModeling/SemiAlgebraicTypes.jl",
    devbranch = "master",
    push_preview = true
)

