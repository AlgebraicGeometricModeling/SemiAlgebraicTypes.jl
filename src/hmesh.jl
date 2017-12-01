export HEdge, HMesh, hmesh, nbv, nbe, nbf, edge, vertex, push_vertex!, push_edge!, push_face, glue_edge!,  prev, opp, ccw_edges, edges_on_face, minimal_edges

import Base: next

mutable struct HEdge
   point::Int64
   next::Int64
   prev::Int64
   opp::Int64
   face::Int64
   
   function HEdge() new(0,0,0,0,0) end

end

mutable struct HMesh
   points::Matrix{Float64}
   edges ::Vector{HEdge}
   faces ::Vector{Int64}

   function HMesh() new(Matrix{Float64}(3,0),HEdge[],Int64[]) end
   
end

"""
 Build a HMesh from the array of points and array of faces
"""
function hmesh(P::Matrix{Float64}, F::Vector{Vector{Int64}} )
    msh = HMesh()
    msh.points = P
    E = Dict{Pair{Int64,Int64},Int64}()
    for f in F
        ne = nbe(msh)
        push_face!(msh,f[1],f[2],f[3],f[4])
        for i in 1:length(f)
            if f[i]< f[i%4+1]
                l = f[i]; u = f[i%4+1]
            else
                u = f[i]; l = f[i%4+1]
            end
            e = get(E, l=>u, 0)
            if e==0
                E[l=>u] = ne+i
            else
                glue_edge!(msh, e, ne+i)
            end
        end
    end
    msh
end

function hmesh(m::Mesh)
    hmesh(m.points, m.faces)
end

nbv(m::HMesh) = size(m.points,2)
nbe(m::HMesh) = length(m.edges)
nbf(m::HMesh) = length(m.faces)

function push_vertex!(m::HMesh, v::Vector{Float64})
    m.points= cat(2,m.points,v)
end

function push_edge!(m::HMesh, e::HEdge)
    push!(m.edges,e)
end

function vertex(m::HMesh, i) m.points[:,i] end
function point(m::HMesh, i) m.edges[i].point end

function edge(m::HMesh, i) m.edges[i] end

function Base.next(m::HMesh, e::Int64)
    m.edges[e].next
end

function opp(m::HMesh, e::Int64)
    m.edges[e].opp
end

function prev(m::HMesh, e::Int64)
    edge(m,e).prev
end

function push_face!(m::HMesh, p1::Int64, p2::Int64, p3::Int64, p4::Int64)
    ne = nbe(m)
    f = nbf(m)+1
    e1 = HEdge(); e1.point=p1; e1.next=ne+2; e1.prev=ne+4; e1.face=f
    e2 = HEdge(); e2.point=p2; e2.next=ne+3; e2.prev=ne+1; e2.face=f
    e3 = HEdge(); e3.point=p3; e3.next=ne+4; e3.prev=ne+2; e3.face=f
    e4 = HEdge(); e4.point=p4; e4.next=ne+1; e4.prev=ne+3; e4.face=f
    push_edge!(m,e1)
    push_edge!(m,e2)
    push_edge!(m,e3)
    push_edge!(m,e4)
    push!(m.faces, ne+1);
end

function glue_edge!(m::HMesh, i::Int64, j::Int64)
    m.edges[i].opp=j
    m.edges[j].opp=i
end

function ccw_edges(m::HMesh, e0::Int64)
    E = Int64[e0]
    o1 = prev(m,e0)
    if o1!= 0
        e1 = opp(m,o1)
    else
        e1 = 0
    end
    while e1 != 0 && e1 != e0
        push!(E,e1)
        o1 = prev(m,e1)
        if o1!= 0
            e1 = opp(m,o1)
        else
            e1=0
        end
    end
    E
end

#----------------------------------------------------------------------
function ccw_edges(m::HMesh)

    M = fill(nbe(m)+1, nbv(m))
    
    for (e,i) in zip(m.edges, 1:nbe(m))
        if i<M[e.point] || opp(m,i) == 0
            M[e.point] = i
        end
    end
    
    E = fill(Int64[], nbv(m))
    for i in 1:nbv(m)
        E[i] = ccw_edges(m, M[i])
    end
    E
end

#----------------------------------------------------------------------
function edges_on_face(m::HMesh, f::Int64)
    e0 = m.faces[f]
    E = [e0]
    e1 = next(m,e0)
    while e1 != 0 && e1 != e0
        push!(E,e1)
        e1 = next(m,e1)
    end
    E
end

#----------------------------------------------------------------------
function minimal_edges(m::HMesh)
    V = fill(nbe(m)+1, nbv(m))
    for (e,i) in zip(m.edges, 1:nbe(m))
        if i<V[e.point] || opp(m,i) == 0
            V[e.point] = i
        end
    end
    V
end
#----------------------------------------------------------------------
