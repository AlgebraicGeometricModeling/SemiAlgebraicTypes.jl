export Line, Sphere, Cylinder, Cone, Ellipsoid, point, sphere, line, cylinder, cone, ellipsoid

point() = Float64[0.0,0.0,0.0]
point(x ::T, y::T) where T = T[x,y]
point(x ::T, y::T, z::T) where T = T[x,y,z]

#----------------------------------------------------------------------
"""
`Line{T}` represented by two points `pt0`, `pt1`.

The type `T` is the promote type of the entry type of `pt0, pt1`.

**Example**

    Line([0,0,0], [1.,0,0])

"""
mutable struct Line{T}
    pt0 :: Vector{T}
    pt1 :: Vector{T}
    attr::Dict{Symbol,Any}
end
function Line(P0::Vector, P1::Vector; args...)
    T = promote_type(eltype(P0), eltype(P1))
    m = Line{T}(P0, P1, Dict{Symbol,Any}())
    for arg in args m[arg[1]]=arg[2] end
    return m
end

function line(P0::Vector,P1::Vector; args...)
    return Line(P0,P1; args...)
end

function Base.getindex(m::Line{T}, s::Symbol) where T
    Base.get(m.attr, s, 0)
end
function Base.setindex!(m::Line{T}, v, s::Symbol) where T
    m.attr[s] = v
end

#----------------------------------------------------------------------
"""
`Sphere{T}` represented by a point `center` and a `radius`.
The type `T` is the promote type of the entry type of `center` and the type of `radius`.

**Example**

    Sphere([0,0,0], 1.)

"""
mutable struct Sphere{T}
    center::Vector{T}
    radius::T
    attr  ::Dict{Symbol,Any}
end

function Sphere(P0::Vector, r; args...)
    T = promote_type(eltype(P0), typeof(r))
    m = Sphere{T}(P0, r, Dict{Symbol,Any}())
    for arg in args m[arg[1]]=arg[2] end
    return m
end

function sphere(P0::Vector,r;args...) 
    return Sphere(P0,r;args...)
end

function Base.getindex(m::Sphere{T}, s::Symbol) where T
    get(m.attr, s, 0)
end
function Base.setindex!(m::Sphere{T}, v, s::Symbol) where T
    m.attr[s] = v
end

#----------------------------------------------------------------------
"""
`Cylinder{T}` represented by two points `pt0`, `pt1` and a number `radius`.
The type `T` is the promote type of the entry type of `pt0, pt1` and the type of `radius`.

**Example**

    Cylinder([0,0,0],[0,0,1], 0.5)

"""
mutable struct Cylinder{T} 
    pt0::Vector{T}
    pt1::Vector{T}
    radius::T
    attr::Dict{Symbol,Any}
    
end

function Cylinder(P0::Vector, P1::Vector, r; args...)
    T = promote_type(eltype(P0), eltype(P1), typeof(r))
    m = Cylinder{T}(P0, P1, r, Dict{Symbol,Any}())
    for arg in args m[arg[1]]=arg[2] end
    return m
end

function cylinder(P0::Vector,P1::Vector,r;args...) 
    Cylinder(P0,P1,r;args...)
end

function Base.getindex(m::Cylinder, s::Symbol)
    Base.get(m.attr, s, 0)
end
function Base.setindex!(m::Cylinder, v, s::Symbol)
    m.attr[s] = v
end

#----------------------------------------------------------------------
"""
`Cone{T}` represented by two points `pt0, pt1` and a number `radius`.
The apex of the cone is the first point. 
The type `T` is the promote type of the entry type of `pt0, pt1` and the type of `radius`.

**Example**

    Cone([1,0,0], [0,0,0], 0.5)

"""
mutable struct Cone{T}
    pt0::Vector{T}
    pt1::Vector{T}
    radius::T
    attr::Dict{Symbol,Any}
end

function Cone(P0::Vector, P1::Vector, r; args...)
    T = promote_type(eltype(P0), eltype(P1), typeof(r))
    m = Cone{T}(P0, P1, r, Dict{Symbol,Any}())
    for arg in args m[arg[1]]=arg[2] end
    return m
end

function cone(P0::Vector,P1::Vector,r;args...)
    return Cone(P0,P1,r)
end

function Base.getindex(m::Cone{T}, s::Symbol) where T
    Base.get(m.attr, s, 0)
end
function Base.setindex!(m::Cone{T}, v, s::Symbol) where T
    m.attr[s] = v
end

#----------------------------------------------------------------------
"""
`Ellipsoid{T}` represented by 

 - `c` the center 
 - `sx, sy, sz` semi-axes. They should be orthogonal but this not checked at the construction. 

The type `T` is the promote type of the entry types of `c, sx, sy, sz`.

**Example**

    Ellipsoid([0,0,0], [1,0,0], [0,0.5,0], [0,0,0.1])

"""
mutable struct Ellipsoid{T}
    c::Vector{T}
    sx::Vector{T}
    sy::Vector{T}
    sz::Vector{T}
    attr::Dict{Symbol,Any}
end

function Ellipsoid(c::Vector,sx::Vector,sy::Vector,sz::Vector;args...) 
    T = promote_type(eltype(c), eltype(sx), eltype(sy), eltype(sz))
    m = Ellipsoid{T}(c,sx,sy,sz,Dict{Symbol,Any}())
    for arg in args m[arg[1]]=arg[2] end
    return m
end

function ellipsoid(c::Vector,sx::Vector,sy::Vector,sz::Vector;args...) 
    return Ellipsoid(c,sx,sy,sz)
end

function Base.getindex(m::Ellipsoid{T}, s::Symbol) where T
    Base.get(m.attr, s, 0)
end
function Base.setindex!(m::Ellipsoid{T}, v, s::Symbol) where T
    m.attr[s] = v
end
