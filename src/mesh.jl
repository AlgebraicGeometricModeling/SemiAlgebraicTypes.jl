export Mesh, Edge, Face, mesh, getindex, nbv, nbe, nbf, push_vertex, push_edge, push_face, push_vertex!, push_edge!, push_face!, cube

import Base: push!, getindex, setindex!, print
#----------------------------------------------------------------------
const Edge = Vector{Int64}
const Face = Vector{Int64}
#----------------------------------------------------------------------
"""
```
Mesh{T}
```
Mesh corresponding to an array of points (`Vector{T}`), an array of edges (`Vector{Int64}`)
and an array of faces (`Vector{Int64}`).

Example
-------
```
mesh(Float64)
mesh([[cos(i*pi/5), sin(i*pi/5), 0.0] for i in 1:10], Edge[], [[1,i,i+1] for i in 1:9])
``` 
The following data are accessible:

  - `m.points ::Vector{Vector{T}}`: array of points
  - `m.edges  ::Vector{Vector{Int64}}`: array of edges
  - `m.faces  ::Vector{Vector{Int64}}`: array of faces
  - `m.attr   ::Dict{String,Any}`: attributes

"""
type Mesh{T}
    points::Vector{Vector{T}}
    edges ::Vector{Vector{Int64}}
    faces ::Vector{Vector{Int64}}
    attr  ::Dict{String,Any}

    function Mesh{T}(pts::Vector{Vector{T}},e::Vector{Vector{Int64}}, f::Vector{Vector{Int64}}, attr::Dict{String,Any}) where T
        new(pts,e,f,attr)
    end

end

function mesh{T}(::Type{T})
    Mesh{T}(Vector{T}[], Vector{Int64}[], Vector{Int64}[], Dict{String,Any}())
end

function mesh{T}(P::Vector{Vector{T}},
                 E::Vector{Edge}=Edge[],
                 F::Vector{Face}=Face[];
                 args...)
    m = Mesh{T}(P,E,F, Dict{String,Any}())
    for arg in args m[string(arg[1])]=arg[2] end
    return m
end 

function getindex{T}(m::Mesh{T}, s::String) get(m.attr, s, 0) end
function setindex!{T}(m::Mesh{T}, v, s::String) m.attr[s] = v end

#----------------------------------------------------------------------
"""
Insert a vertex at the end of the vertex array.
```
push_vertex!(m,[1.,2.,3.])
```
"""
function push_vertex!{T}(m::Mesh{T}, v::Vector{T})
    push!(m.points,v)
    m
end

#----------------------------------------------------------------------
"""
Insert a new edge given by the array of indices of the points (numbering starting at 1)
at the end of the edge array.
```
m = mesh(Float64) 
push_vertex!(m,point(0.,0.,0.))
push_vertex!(m,point(1.,0.,0.))
push_edge!(m,[1,2]) end
```
"""
function push_edge!{T}(m::Mesh{T}, e::Vector{Int64})
    push!(m.edges,e)
    m
end

#----------------------------------------------------------------------
"""
Insert a new face with the array of indices of the points (numbering starting at 1)
at the end of the face array.
```
m = mesh(Float64) 
for i in 1:10 push_vertex!(m,[cos(i*pi/5), sin(i*pi/5), 0.0]) end
for i in 1:9 push_face!(m,[1,i,i+1]) end
```
"""
function push_face!{T}(m::Mesh{T}, f::Vector{Int64})
    push!(m.faces,f)
    m
end

nbv{T}(m::Mesh{T}) = length(m.points)
nbe{T}(m::Mesh{T}) = length(m.edges)
nbf{T}(m::Mesh{T}) = length(m.faces)

#----------------------------------------------------------------------
"""
Compute the mesh corresponding to a cube aligned with the axes and centered 
at the point c of size 2r
"""
function cube{T}(c::Vector{T}, r::T; args...)
    m = mesh(T)
    push_vertex!(m,c+[-r,-r,-r])
    push_vertex!(m,c+[r,-r,-r])
    push_vertex!(m,c+[r,r,-r])
    push_vertex!(m,c+[-r,r,-r])
    
    push_vertex!(m,c+[-r,-r,r])
    push_vertex!(m,c+[r,-r,r])
    push_vertex!(m,c+[r,r,r])
    push_vertex!(m,c+[-r,r,r])
    
    push_face!(m, [1,2,3,4])
    push_face!(m, [5,6,7,8])
    push_face!(m, [1,2,6,5])
    push_face!(m, [3,4,8,7])
    push_face!(m, [1,4,8,5])
    push_face!(m, [2,3,7,6])

    for arg in args m[string(arg[1])]=arg[2] end
    return m
end
