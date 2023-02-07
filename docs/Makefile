all: SemiAlgebraicTypes.jl
	julia --color=yes make.jl

SemiAlgebraicTypes.jl:
	git clone -b gh-pages https://github.com/AlgebraicGeometricModeling/SemiAlgebraicTypes.jl.git

publish:
	cd SemiAlgebraicTypes.jl; git add docs; git commit -am "update gh-pages"; git push
