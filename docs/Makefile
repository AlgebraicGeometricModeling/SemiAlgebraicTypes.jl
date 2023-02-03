all: 
	julia --color=yes make.jl
web:
	rsync -a ./html/ ci@excalibur2.inria.fr:/var/www/html/axel/public/latest/doc/SemiAlgebraicTypes.jl
