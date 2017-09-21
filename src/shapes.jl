export Line, Sphere, Cylinder, Cone, point, sphere, line, cylinder, cone

point{T}(x ::T, y::T) = T[x,y]
point{T}(x ::T, y::T, z::T) = T[x,y,z]
#----------------------------------------------------------------------
"""
``` 
Line{T}
```
Line represented by two points.
"""

type Line{T}
    pt0 :: Vector{T}
    pt1 :: Vector{T}
    attr::Dict{String,Any}
end

function line{T}(P0::Vector{T},P1::Vector{T};args...)
    m = Line(P0,P1,Dict{String,Any}())
    for arg in args m[string(arg[1])]=arg[2] end
    m
end

function Base.getindex{T}(m::Line{T}, s::String) Base.get(m.attr, s, 0) end
function Base.setindex!{T}(m::Line{T}, v, s::String) m.attr[s] = v end

#----------------------------------------------------------------------
"""
``` 
Sphere{T}
```
Sphere represented by a center and a radius.
"""
type Sphere{T}
    center::Vector{T}
    radius::T
    attr  ::Dict{String,Any}
end

function sphere{T}(P0::Vector{T},r::T;args...)
    m = Sphere(P0,r,Dict{String,Any}())
    for arg in args m[string(arg[1])]=arg[2] end
    m
end

function Base.getindex{T}(m::Sphere{T}, s::String) get(m.attr, s, 0) end
function Base.setindex!{T}(m::Sphere{T}, v, s::String) m.attr[s] = v end

#----------------------------------------------------------------------
"""
``` 
Cylinder{T}
```
Cylinder represented by two points and a radius.
"""
type Cylinder{T}
    pt0::Vector{T}
    pt1::Vector{T}
    radius::T
    attr::Dict{String,Any}
end

function cylinder{T}(P0::Vector{T},P1::Vector{T},r::T;args...)
    m = Cylinder(P0,P1,r,Dict{String,Any}())
    for arg in args m[string(arg[1])]=arg[2] end
    m
end
function Base.getindex{T}(m::Cylinder{T}, s::String) Base.get(m.attr, s, 0) end
function Base.setindex!{T}(m::Cylinder{T}, v, s::String) m.attr[s] = v end

#----------------------------------------------------------------------
"""
``` 
Cone{T}
```
Cone represented by two points and a radius.
"""
type Cone{T}
    pt0::Vector{T}
    pt1::Vector{T}
    radius::T
    attr::Dict{String,Any}
end

function cone{T}(P0::Vector{T},P1::Vector{T},r::T;args...)
    m = Cone(P0,P1,r,Dict{String,Any}())
    for arg in args m[string(arg[1])]=arg[2] end
    m
end
function Base.getindex{T}(m::Cone{T}, s::String) Base.get(m.attr, s, 0) end
function Base.setindex!{T}(m::Cone{T}, v, s::String) m.attr[s] = v end

#----------------------------------------------------------------------
