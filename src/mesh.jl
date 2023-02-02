export Mesh, Edge, Face, mesh, copy, getindex, nbv, nbe, nbf,
    point, edge, face, normal,
    push_vertex!, push_edge!, push_face!, push_normal!,
    remove_doublon!, 
    cube

import Base: push!, getindex, setindex!, print, join
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
```jldoctest
julia> mesh(Float64);

julia> mesh([[cos(i*pi/5), sin(i*pi/5), 0.0] for i in 1:10], Edge[], [[1,i,i+1] for i in 1:9]);
```

**Fields:**

  - `points  ::Matrix{T}`: array of points
  - `edges   ::Vector{Vector{Int64}}`: array of edges
  - `faces   ::Vector{Vector{Int64}}`: array of faces
  - `normals ::Matrix{T}`: array of normals
  - `attr    ::Dict{Symbol,Any}`: attributes
"""
mutable struct Mesh{T}
    points::Matrix{T}

    edges  ::Vector{Vector{Int64}}
    faces  ::Vector{Vector{Int64}}
    normals::Matrix{T}
    attr   ::Dict{Symbol,Any}

    function Mesh{T}(pts::Matrix{T}, e::Vector{Vector{Int64}}, f::Vector{Vector{Int64}}, normals::Matrix{T}, attr::Dict{Symbol,Any}) where T
        new(pts,e,f,normals,attr)
    end

end

function mesh(::Type{T}, n::Int64 = 3;
              args...) where T
    m = Mesh{T}(Matrix{T}(undef,n,0), Vector{Int64}[], Vector{Int64}[], Matrix{T}(undef,n,0), Dict{Symbol,Any}())
    for arg in args m[arg[1]]=arg[2] end
    return m
end

function mesh(P::Matrix{T},
              E::Vector{Edge}=Edge[],
              F::Vector{Face}=Face[],
              N::Matrix{T}=Matrix{T}(undef,size(P,1),0);
              args...) where T
    m = Mesh{T}(P,E,F,N, Dict{Symbol,Any}())
    for arg in args m[arg[1]]=arg[2] end
    return m
end

function mesh(L::Vector{Vector{T}},
              E::Vector{Edge}=Edge[],
              F::Vector{Face}=Face[],
              N::Matrix{T} = Matrix{T}(undef,length(L[1]),0);
              args...) where T
    P = fill(zero(T),length(L[1]), length(L))
    for i in 1:length(L)
        P[:,i]= L[i]
    end
    m = Mesh{T}(P,E,F,N, Dict{Symbol,Any}())
    for arg in args m[arg[1]]=arg[2] end
    return m
end

function Base.copy(m:: Mesh{T}) where T
  return Mesh{T}(copy(m.points), copy(m.edges), copy(m.faces), copy(m.normals), m.attr)
end

function getindex(m::Mesh{T}, s::Symbol) where T
    get(m.attr, s, 0)
end
function setindex!(m::Mesh{T}, v, s::Symbol) where T
    m.attr[s] = v
end


#----------------------------------------------------------------------
"""
Insert a vertex at the end of the vertex array of a mesh.
```jldoctest
julia> m = mesh(Float64,3);

julia> push_vertex!(m,[1.,2.,3.])
SemiAlgebraicTypes.Mesh{Float64}(Array{Float64,1}[[1.0, 2.0, 3.0]], Array{Int64,1}[], Array{Int64,1}[], Dict{Symbol,Any}())

```
"""
function push_vertex!(m::Mesh{T}, v::Vector{T}) where T
    m.points = hcat(m.points, v)
    return size(m.points,2)
end


#----------------------------------------------------------------------
"""
Insert a new edge given by the array of indices of the points (numbering starting at 1)
at the end of the edge array of the mesh.
```jldoctest
julia> m = mesh(Float64);

julia> push_vertex!(m,point(0.,0.,0.)); push_vertex!(m,point(1.,0.,0.)); push_edge!(m,[1,2])
SemiAlgebraicTypes.Mesh{Float64}(Array{Float64,1}[[0.0, 0.0, 0.0], [1.0, 0.0, 0.0]], Array{Int64,1}[[1, 2]], Array{Int64,1}[], Dict{Symbol,Any}())

```
"""
function push_edge!(m::Mesh{T}, e::Vector{Int64}) where T
    push!(m.edges,e)
    m
end

#----------------------------------------------------------------------
"""
Insert a new face with the array of indices of the points (numbering starting at 1)
at the end of the face array.
```jldoctest
julia> m = mesh(Float64);

julia> for i in 1:10 push_vertex!(m,[cos(i*pi/5), sin(i*pi/5), 0.0]) end;

julia> for i in 1:9 push_face!(m,[1,i,i+1]) end;
```
"""
function push_face!(m::Mesh{T}, f::Vector{Int64}) where T
    push!(m.faces,f)
    m
end

#----------------------------------------------------------------------
function push_normal!(m, v::Vector{T}) where T
    m.normals = hcat(m.normals, v)
end

#----------------------------------------------------------------------
"""
Number of vertices of the mesh m
"""
nbv(m::Mesh{T}) where T = size(m.points,2)
"""
Number of edges of the mesh m
"""
nbe(m::Mesh{T}) where T = length(m.edges)
"""
Number of faces of the mesh m
"""
nbf(m::Mesh{T}) where T = length(m.faces)

#----------------------------------------------------------------------
"""
 Point of index i in the mesh m, as a Vector{T}.
"""
function point(m::Mesh{T}, i::Int64) where T
    return m.points[:,i]
end
#----------------------------------------------------------------------
"""
 Edge of index i in the mesh m, as a Vector{Int64} containing the
 indices of the vertices of the edge.
"""
function edge(m::Mesh{T}, i::Int64) where T
    return m.edges[i]
end
#----------------------------------------------------------------------
"""
 Face of index i in the mesh m, as a Vector{Int64} containing the
 indices of the vertices on the face boundary.
"""
function face(m::Mesh{T}, i::Int64) where T
    return m.faces[i]
end
#----------------------------------------------------------------------
function normal(m::Mesh{T}, i::Int64) where T
    return m.normals[:,i]
end
#----------------------------------------------------------------------
"""
Replace duplicate points which are within distance eps by a single point.

The default value for eps is 1.e-3.

Warning: The normals are not aken into account.
"""
function remove_doublon!(m::Mesh{Float64}, eps::Float64=1.e-3)
    P = Matrix{Float64}(undef,3,0)
    Idx = fill(0,nbv(m))
    c = 1
    for i in 1:nbv(m)
        Idx[i]=i
        pt = m.points[:,i]
        for j in 1:size(P,2)
            if LinearAlgebra.norm(P[:,j]-pt) < eps
                Idx[i]=j
                j = size(P,2)+1
            end
        end
        if Idx[i] == i
            P = hcat(P,pt)
            Idx[i] = c
            c+=1
        end
    end

    E = Vector{Int64}[]
    for e in m.edges
        ne = Int64[]
        for i in e
            push!(ne, Idx[i])
        end
        push!(E,ne)
    end
    
    F = Vector{Int64}[]
    for f in m.faces
        nf = Int64[]
        for i in f
            push!(nf, Idx[i])
        end
        push!(F,nf)
    end

    m.points = P
    m.edges  = E
    m.faces  = F
end

#----------------------------------------------------------------------
"""
```
join(M::Mesh{Float64}...)
```
Join the meshes M into a single mesh.

"""
function Base.join(M::Mesh{Float64}...)

  
    m = mesh(Float64)
    m.points = hcat([mi.points for mi in M]...)
    m.edges  = vcat([mi.edges for mi in M]...)
    m.faces  = vcat([mi.faces for mi in M]...)
    m.normals= hcat([mi.normals for mi in M]...)

    nv = nbv(M[1])
    ne = nbe(M[1])
    nf = nbf(M[1])

    for k in 2:length(M)
        for i in ne+1:ne+nbe(M[k])
            for j in 1:length(m.edges[i])
                m.edges[i][j] += nv
            end
        end

        for i in nf+1:nf+nbf(M[k])
            for j in 1:length(m.faces[i])
                m.faces[i][j] += nv
            end
        end
        nv += nbv(M[k])
        ne += nbe(M[k])
        nf += nbf(M[k])
    end
    #remove_doublon!(m)
    return m
end  


#----------------------------------------------------------------------
"""
```
cube(c::Vector{T},r::T)
```
Compute the mesh corresponding to a cube aligned with the axes and centered
at the point c of size 2r.
"""
function cube(c::Vector{T}, r::T; args...) where T
    m = mesh(T)
    push_vertex!(m,c+[-r,-r,-r])
    push_vertex!(m,c+[r,-r,-r])
    push_vertex!(m,c+[r,r,-r])
    push_vertex!(m,c+[-r,r,-r])

    push_vertex!(m,c+[-r,-r,r])
    push_vertex!(m,c+[r,-r,r])
    push_vertex!(m,c+[r,r,r])
    push_vertex!(m,c+[-r,r,r])

    push_edge!(m, [1,2])
    push_edge!(m, [2,3])
    push_edge!(m, [3,4])
    push_edge!(m, [1,4])
    push_edge!(m, [5,6])
    push_edge!(m, [6,7])
    push_edge!(m, [7,8])
    push_edge!(m, [5,8])
    push_edge!(m, [1,5])
    push_edge!(m, [2,6])
    push_edge!(m, [3,7])
    push_edge!(m, [4,8])

    push_face!(m, [1,2,3,4])
    push_face!(m, [5,6,7,8])
    push_face!(m, [1,2,6,5])
    push_face!(m, [3,4,8,7])
    push_face!(m, [1,4,8,5])
    push_face!(m, [2,3,7,6])

    for arg in args m[arg[1]]=arg[2] end
    return m
end

export face_orientation
"""
Compute a sequence of arrows starting at the center of each face and pointing in the direction of the oriented normal to the face (cross product of 2 first edge vectors).

The size of the arrow is proportional to the area of the triangl of the 3 first points of the face.
"""
function face_orientation(m::Mesh{T}) where T
    R = Any[]
    for f in m.faces
        p = (m.points[:,f]*fill(1.0,length(f)))/length(f)
        n = cross(m.points[:,f[2]] - m.points[:,f[1]], m.points[:,f[3]] - m.points[:,f[2]])
        s = norm(n)
        n/= s
        r = sqrt(s)/40
        push!(R, cylinder(p, p+3*r*n,r/2; color=Axl.red))
        push!(R, cone(p+6*r*n,p+3*r*n,r; color=Axl.red))
    end
    return R
end


"""
```
cube(p1::Vector{T}, p2::Vector{T})
```
Compute the mesh corresponding to a cube aligned with the axes with diagonal points p1, p2.
"""
function cube(p1::Vector{T}, p2::Vector{T}; args...) where T
    m = mesh(T)

    push_vertex!(m, [p1[1],p1[2],p1[3]])
    push_vertex!(m, [p2[1],p1[2],p1[3]])
    push_vertex!(m, [p2[1],p2[2],p1[3]])
    push_vertex!(m, [p1[1],p2[2],p1[3]])

    push_vertex!(m, [p1[1],p1[2],p2[3]])
    push_vertex!(m, [p2[1],p1[2],p2[3]])
    push_vertex!(m, [p2[1],p2[2],p2[3]])
    push_vertex!(m, [p1[1],p2[2],p2[3]])

    push_edge!(m, [1,2])
    push_edge!(m, [2,3])
    push_edge!(m, [3,4])
    push_edge!(m, [1,4])
    push_edge!(m, [5,6])
    push_edge!(m, [6,7])
    push_edge!(m, [7,8])
    push_edge!(m, [5,8])
    push_edge!(m, [1,5])
    push_edge!(m, [2,6])
    push_edge!(m, [3,7])
    push_edge!(m, [4,8])

    push_face!(m, [1,2,3,4])
    push_face!(m, [5,6,7,8])
    push_face!(m, [1,2,6,5])
    push_face!(m, [3,4,8,7])
    push_face!(m, [1,4,8,5])
    push_face!(m, [2,3,7,6])

    for arg in args m[arg[1]]=arg[2] end
    return m
end
