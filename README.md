The package `SemiAlgebraicTypes.jl` provides implementation of semialgebraic sets such as points, spheres, lines cones, bspline functions, ...

To install the package within julia:

```julia
using Pkg
Pkg.add(PackageSpec(url="https://gitlab.inria.fr/AlgebraicGeometricModeling/SemiAlgebraicTypes.jl.git"))
```


To use it within julia:

```julia
using SemiAlgebraicTypes

A = point(0.,0.,0.)
B = point(0.,0.,1.)
C = point(0.,0.,3.)

l0 = line(A,B)
c0 = cylinder(A,B,0.2)
c1 = cone(C,B,0.7)
s0 = sphere(c0.pt1,c1.radius)

m = mesh([[cos(i*pi/5), sin(i*pi/5), 0.0] for i in 1:10], Edge[], [[1,i,i+1] for i in 1:9])

B1 = BSplineBasis(linspace(0., 2., 4), 3)
B2 = BSplineBasis(linspace(0., 1., 3), 3)

f1 = BSplineFunction1D(rand(3,5), B1; color=color(0,255,0))
f2 = BSplineFunction2D(rand(3,5,4), B1,B2; color=color(50,50,255))
```

