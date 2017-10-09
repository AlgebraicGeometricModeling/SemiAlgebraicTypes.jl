using Documenter, SemiAlgebraicTypes

dir = "mrkd"
Expl = []; 
Code = ["code.md", "mesh.md"];

makedocs(
         format = :html,
         sitename = "SemiAlgebraicTypes.jl",
         authors = "B. Mourrain",
         modules = [SemiAlgebraicTypes],
         build = "html",
         source = dir,
         pages = Any[
                     "Home" => "index.md",
                     "Example" => Expl,
                     "SemiAlgebraic types" => Code
                     ],
         repo = "https://gitlab.inria.fr/AlgebraicGeometricModeling/SemiAlgebraicTypes.jl/tree/master",
         doctest = false
         )

deploydocs(
           deps = Deps.pip("mkdocs", "python-markdown-math"),
           repo = "gitlab.inria.fr/AlgebraicGeometricModeling/SemiAlgebraicTypes.jl.git",
           target = "site",
           julia  = "0.6",
           osname = "osx",
           deps = nothing,
           make = nothing
           )
