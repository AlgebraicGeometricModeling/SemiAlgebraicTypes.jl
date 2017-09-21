export mesh, Edge, Face, getindex, nbv, nbe, nbf, push_vertex, push_edge, push_face, push_vertex!, push_edge!, push_face!

import Base: push!, getindex, setindex!, print
#----------------------------------------------------------------------
const Edge = Vector{Int64}
const Face = Vector{Int64}
#----------------------------------------------------------------------
"""
```
mesh{T}
```
Mesh corresponding to an array of points (`Vector{T}`), an array of edges (`Vector{Int64}`)
and an array of faces (`Vector{Int64}`).

Additional attribute can be associated to a mesh, such as color, fields, ...
   - [Color](@ref): a color given by its rgb components 
   - [DirField](@ref): a colormap value corresponding to the scalar product with a vector.
   - [DistField](@ref): a colormap value corresponding to the distance to a point.

Example
-------
```
mesh([[cos(i*pi/5), sin(i*pi/5), 0.0] for i in 1:10], Edge[], [[1,i,i+1] for i in 1:9])
mesh([[cos(i*pi/5), sin(i*pi/5), 0.0] for i in 1:10], Edge[], [[1,i,i+1] for i in 1:9])
m = mesh(Float64); for i in 1:10 push_vertex!(m,[cos(i*pi/5), sin(i*pi/5), 0.0]) end; for i in 1:9 push_face!(m,[1,i,i+1]) end
``` 
"""
type mesh{T}
    points::Vector{Vector{T}}
    edges ::Vector{Vector{Int64}}
    faces ::Vector{Vector{Int64}}
    attr  ::Dict{String,Any}
end

mesh{T}(::Type{T}) = mesh(Vector{T}[],Vector{Int64}[], Vector{Int64}[])

function mesh{T}(P::Vector{Vector{T}},
                 E::Vector{Edge}=Edge[],
                 F::Vector{Face}=Face[];
                 args...)
    m = mesh(P,E,F, Dict{String,Any}())
    for arg in args m[string(arg[1])]=arg[2] end
    return m
end 

function getindex{T}(m::mesh{T}, s::String) get(m.attr, s, 0) end
function setindex!{T}(m::mesh{T}, v, s::String) m.attr[s] = v end

function push_vertex!{T}(m::mesh{T}, v::Vector{T})
    push!(m.points,v)
    m
end

function push_edge!{T}(m::mesh{T}, e::Vector{Int64})
    push!(m.edges,e)
    m
end

function push_face!{T}(m::mesh{T}, f::Vector{Int64})
    push!(m.faces,f)
    m
end

nbv{T}(m::mesh{T}) = length(m.points)
nbe{T}(m::mesh{T}) = length(m.edges)
nbf{T}(m::mesh{T}) = length(m.faces)

#----------------------------------------------------------------------
