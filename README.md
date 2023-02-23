The package `SemiAlgebraicTypes.jl` provides implementation of semialgebraic sets such as points, spheres, lines, cylinders, cones, ellipsoids, meshes, bspline functions, ...

## Installation

To install the package within julia:

```julia
] add https://github.com/AlgebraicGeometricModeling/SemiAlgebraicTypes.jl
```
(`]` key switches to the pkg mode)

## Example
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

B1 = BSplineBasis(LinRange(0., 2., 4), 3)
B2 = BSplineBasis(LinRange(0., 1., 3), 3)

f1 = BSplineCurve(rand(3,5), B1); f1(0.)
f2 = BSplineSurface(rand(3,5,4), B1,B2); f2(0.,0.)
f3 = BSplineVolume(rand(3,5,4, 4), B1,B2, B2); f3(0.,0.,0.)
```
## Documentation

[![](https://img.shields.io/badge/docs-latest-blue.svg)](https://AlgebraicGeometricModeling.github.io/SemiAlgebraicTypes.jl)
