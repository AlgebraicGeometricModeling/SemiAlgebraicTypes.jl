using Documenter, SemiAlgebraicTypes

Expl = []; 
Code = ["code.md", "mesh.md"];

makedocs(
         sitename = "SemiAlgebraicTypes.jl",
         authors = "B. Mourrain",
         modules = [SemiAlgebraicTypes],
#         build = "html",
         source = "mrkd",
         pages = Any[
                     "Home" => "index.md",
                     "Example" => Expl,
                     "SemiAlgebraic types" => Code
                     ],
 #        repo = "https://gitlab.inria.fr/AlgebraicGeometricModeling/SemiAlgebraicTypes.jl/tree/master",
         doctest = false
         )

deploydocs(
    root = "../docs",
    repo = "github.com/AlgebraicGeometricModeling/SemiAlgebraicTypes.jl.git",
    devbranch = "master",
    push_preview = true,
)

