export Line, Sphere, Cylinder, Cone, Ellipsoid, point, sphere, line, cylinder, cone, ellipsoid

point() = Float64[0.0,0.0,0.0]
point(x ::T, y::T) where T = T[x,y]
point(x ::T, y::T, z::T) where T = T[x,y,z]

#----------------------------------------------------------------------
"""
```
Line{T}
```
Line represented by two points.
"""
mutable struct Line{T}
    pt0 :: Vector{T}
    pt1 :: Vector{T}
    attr::Dict{Symbol,Any}
end

function line(P0::Vector{T},P1::Vector{T};args...) where T
    m = Line(P0,P1,Dict{Symbol,Any}())
    for arg in args m[arg[1]]=arg[2] end
    m
end

function Base.getindex(m::Line{T}, s::Symbol) where T
    Base.get(m.attr, s, 0)
end
function Base.setindex!(m::Line{T}, v, s::Symbol) where T
    m.attr[s] = v
end

#----------------------------------------------------------------------
"""
```
Sphere{T}
```
Sphere represented by a center and a radius.
"""
mutable struct Sphere{T}
    center::Vector{T}
    radius::T
    attr  ::Dict{Symbol,Any}
end

function sphere(P0::Vector{T},r::T;args...) where T
    m = Sphere(P0,r,Dict{Symbol,Any}())
    for arg in args m[arg[1]]=arg[2] end
    m
end

function Base.getindex(m::Sphere{T}, s::Symbol) where T
    get(m.attr, s, 0)
end
function Base.setindex!(m::Sphere{T}, v, s::Symbol) where T
    m.attr[s] = v
end

#----------------------------------------------------------------------
"""
```
Cylinder{T}
```
Cylinder represented by two points and a radius.
"""
mutable struct Cylinder{T}
    pt0::Vector{T}
    pt1::Vector{T}
    radius::T
    attr::Dict{Symbol,Any}
end

function cylinder(P0::Vector{T},P1::Vector{T},r::T;args...) where T
    m = Cylinder(P0,P1,r,Dict{Symbol,Any}())
    for arg in args m[arg[1]]=arg[2] end
    m
end
function Base.getindex(m::Cylinder{T}, s::Symbol) where T
    Base.get(m.attr, s, 0)
end
function Base.setindex!(m::Cylinder{T}, v, s::Symbol) where T
    m.attr[s] = v
end

#----------------------------------------------------------------------
"""
```
Cone{T}
```
Cone represented by two points and a radius.
"""
mutable struct Cone{T}
    pt0::Vector{T}
    pt1::Vector{T}
    radius::T
    attr::Dict{Symbol,Any}
end

function cone(P0::Vector{T},P1::Vector{T},r::T;args...) where T
    m = Cone(P0,P1,r,Dict{Symbol,Any}())
    for arg in args m[arg[1]]=arg[2] end
    m
end
function Base.getindex(m::Cone{T}, s::Symbol) where T
    Base.get(m.attr, s, 0)
end
function Base.setindex!(m::Cone{T}, v, s::Symbol) where T
    m.attr[s] = v
end

#----------------------------------------------------------------------
"""
```
Ellipsoid{T}
```
Ellipsoid represented by 
 - c the center 
 - sx, sy, sz semi-axes 
"""
mutable struct Ellipsoid{T}
    c::Vector{T}
    sx::Vector{T}
    sy::Vector{T}
    sz::Vector{T}
    attr::Dict{Symbol,Any}
end

function ellipsoid(c::Vector{T},sx::Vector{T},sy::Vector{T},sz::Vector{T};args...) where T
    m = Ellipsoid(c,sx,sy,sz,Dict{Symbol,Any}())
    for arg in args m[arg[1]]=arg[2] end
    m
end

function Base.getindex(m::Ellipsoid{T}, s::Symbol) where T
    Base.get(m.attr, s, 0)
end
function Base.setindex!(m::Ellipsoid{T}, v, s::Symbol) where T
    m.attr[s] = v
end
