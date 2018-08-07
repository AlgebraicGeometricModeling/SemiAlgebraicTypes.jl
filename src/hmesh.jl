export HEdge, copy, HMesh, hmesh, nbv, nbe, nbf, edge, vertex, point_of, vertex_of,
    push_vertex!, push_edge!, push_face!, split_edge!, split_face!, glue_edge!,
    prev, opp, face, ccw_edges, edges_on_face, minimal_edges, subdivide_middle!

import Base: next,  getindex, setindex!, print

mutable struct HEdge
    point::Int64
    next::Int64
    prev::Int64
    opp::Int64
    face::Int64

    function HEdge()
        new(0,0,0,0,0)
    end

    function HEdge(v::Int64, n::Int64, p::Int64, o::Int64, f::Int64)
        new(v,n,p,o,f)
    end

    function HEdge(e::HEdge)
        new(e.point,e.next,e.prev,e.opp,e.face)
    end

    function copy(e::HEdge)
        new(e.point,e.next,e.prev,e.opp,e.face)
    end

end

mutable struct HMesh
    points::Matrix{Float64}
    edges ::Vector{HEdge}
    faces ::Vector{Int64}
    normals::Matrix{Float64}
    attr  ::Dict{Symbol,Any}

    function HMesh()
        new(Matrix{Float64}(3,0),HEdge[],Int64[],Matrix{Float64}(3,0), Dict{Symbol,Any}())
    end

    function HMesh(pts::Matrix{Float64},
                   e::Vector{HEdge},
                   f::Vector{Vector{Int64}},
                   normals::Matrix{Float64},
                   attr::Dict{Symbol,Any})
        new(pts,e,f,normals,attr)
    end
end

"""
 Build a HMesh from the array of points and array of faces
"""
function hmesh(P::Matrix{Float64}, F::Vector{Vector{Int64}},N::Matrix{Float64}=Matrix{Float64}(3,0); args...)
    msh = HMesh()
    msh.points = P
    msh.normals = N
    E = Dict{Pair{Int64,Int64},Int64}()
    for f in F
        ne = nbe(msh)
        push_face!(msh,f) #f[1],f[2],f[3],f[4])
        for i in 1:length(f)
            sf = length(f)
            if f[i]< f[i%sf+1]
                l = f[i]; u = f[i%sf+1]
            else
                u = f[i]; l = f[i%sf+1]
            end

            e = get(E, l=>u, 0)
            if e==0
                E[l=>u] = ne+i
            else
                glue_edge!(msh, e, ne+i)
            end
        end
    end
    for arg in args msh[string(arg[1])]=arg[2] end
    return msh
end

function hmesh(m::Mesh{Float64})
    hmesh(m.points, m.faces,m.normals)
end

function Base.getindex(m::HMesh, s::Symbol)
    get(m.attr, s, 0)
end

# function Base.getindex(m::HMesh, e::Int64)
#      m.edges[e]
# end

function setindex!(m::HMesh, v, s::Symbol)
    m.attr[s] = v
end

nbv(m::HMesh) = size(m.points,2)
nbe(m::HMesh) = length(m.edges)
nbf(m::HMesh) = length(m.faces)

function push_vertex!(m::HMesh, v::Vector{Float64})
    m.points= cat(2,m.points,v)
    return nbv(m)
end

function push_edge!(m::HMesh, e::HEdge)
    push!(m.edges,e)
    return nbe(m)
end

#function vertex(m::HMesh, i) m.points[:,i] end

function edge(m::HMesh, i) m.edges[i] end

function point(m::HMesh, i) m.edges[i].point end

function vertex_of(m::HMesh, e) m.edges[e].point end

function point_of(m::HMesh, e) m.points[:, m.edges[e].point] end

function Base.next(m::HMesh, e::Int64)
    m.edges[e].next
end

function opp(m::HMesh, e::Int64)
    m.edges[e].opp
end

function prev(m::HMesh, e::Int64)
    edge(m,e).prev
end

function face(m::HMesh, e::Int64)
    edge(m,e).face
end

function push_face!(m::HMesh, e1::Int64)
    push!(m.faces,e1)
    return nbf(m)
end

function push_face!(m::HMesh, F::Array{Int64})
    ne = nbe(m)
    f = nbf(m)+1
    for i in 1:length(F)
        e = HEdge()
        e.point= F[i]
        e.next = ne+i%length(F)+1
        if i == 1
            e.prev = ne+length(F)
        else
            e.prev = ne+i-1
        end
        e.face = f
        push_edge!(m,e)
    end
    push!(m.faces, ne+1);
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

# function split_edge!(m::HMesh, e0::Int64, v::Int64)
#     if point(m, e0) != v

#         H1 = HEdge(edge(m, e0))

#         H1.point = v
#         H1.next = Base.next(m,e0)
#         H1.prev = e0

#         push_edge!(m,H1)

#         e1 = nbe(m)
#         edge(m, e0).next = e1
#         edge(m, e1).prev = e0

#         if SemiAlgebraicTypes.opp(m,e0) != 0
#             o0 = opp(m,e0)
#             O1 = HEdge(edge(m,o0))
#             O1.point = v
#             O1.prev  = o0
#             O1.next  = next(m, o0)
#             push_edge!(m, O1)
#             o1 = nbe(m)

#             edge(m,o0).next = o1
#             edge(m,o1).prev = o0
#             edge(m,e0).opp = o1
#             edge(m,o1).opp = e0
#             edge(m,e1).opp = o0
#             edge(m,o0).opp = e1
#         end
#     end
# end

"""
  Insert the point of index p in the edge e and its opposite if it exists.
"""
function split_edge!(m, e, p)

    NE = HEdge(edge(m,e))
    NE.point = p
    NE.prev  = e

    ne = push_edge!(m,NE)

    edge(m,edge(m,e).next).prev = ne
    edge(m,e).next = ne

    o = edge(m,e).opp
    if o !=0

        NO = HEdge(edge(m,o))

        NO.next = o
        NO.opp = ne

        no = push_edge!(m,NO)

        edge(m,o).point = p
        edge(m,o).prev = no

        edge(m,ne).opp = no
        edge(m,no).opp = ne

        edge(m,edge(m,no).prev).next = no

    end
end


# function split_face!(m::HMesh, f::Int64, v0::Int64, v1::Int64)
#     e1 = f
#     v = point(m,e1)
#     while v!=v0 && v!=v1
#         e1 = next(m,e1)
#         v = point(m,e1)
#     end
#
#     e2 = next(m,e1)
#     v  = point(m,e2)
#     while v!=v0 && v!=v1
#         e2 = next(m,e2)
#         v = point(m,e2)
#     end
#
#     push_face!(m,e1)
#     f0 = face(m,e1)
#     f1 = nbf(m)
#
#     edge(m,e1).face = f1
#     e = next(m,e1)
#     while e !=e2
#         edge(m,e).face = f1
#         e = next(m,e)
#     end
#
#     p1 = prev(m,e1)
#     H1 = HEdge(point(m,e1),e2,p1,0,f0)
#     push_edge!(m,H1)
#     n1 = nbe(m)
#     edge(m,p1).next = n1
#
#     p2 = prev(m,e2)
#     O1 = HEdge(point(m,e2),e1,p2,0,f1)
#     push_edge!(m,O1)
#     n2 = nbe(m)
#     edge(m,p2).next = n2
#     edge(m,n1).opp  = n2
#     edge(m,n2).opp  = n1
#
# end

"""
   Split the face f by inserting the edge between the vertices v0 and v1.
   A new face is added at the end of the array of faces.
"""
function split_face!(m, fidx, v1,  v2)

    ef = m.faces[fidx]
    p = edge(m,ef).point
    e = edge(m,ef).next
    while p != v1 && e != ef
        p = edge(m,e).point
        e = edge(m,e).next
    end
    e1 = edge(m,e).prev
    while p != v2 && e != ef
        p = edge(m,e).point
        e = edge(m,e).next
    end
    e2 = edge(m,e).prev

    E1 = HEdge(edge(m,e1))
    E2 = HEdge(edge(m,e2))

    E1.next=e2
    E2.next=e1
    E1.face = nbf(m)+1
    E2.face = fidx

    ne1 = push_edge!(m,E1)
    ne2 = push_edge!(m,E2)

    edge(m,ne1).opp = ne2
    edge(m,ne2).opp = ne1

    edge(m,edge(m,e1).prev).next = ne1
    edge(m,edge(m,e2).prev).next = ne2

    edge(m,e1).prev = ne2
    edge(m,e2).prev = ne1

    m.faces[fidx] = ne2

    nf = push_face!(m,ne1)

    edge(m,ne1).face=nf
    e = edge(m, ne1).next
    while e != ne1
        edge(m,e).face=nf
        e = edge(m,e).next
    end

end

"""
    Subdivide each face by inserting the middle of the edges and the middle of the faces.
"""
function subdivide_middle!(m)
    N = nbv(m)
    E = nbe(m)
    for e in 1:E
        p1 = edge(m,e).point
        p2 = edge(m,edge(m,e).next).point

        if p1<= N && p2<= N
            P =  (m.points[:,p1]+m.points[:,p2])/2.0
            p = push_vertex!(m,P)
            split_edge!(m, e, p)
        end
    end
    for f in 1:nbf(m)
        M = Int64[]
        e0 = m.faces[f]
        if edge(m,e0).point > N
            push!(M, edge(m,e0).point)
        end
        e = edge(m,e0).next
        while e != e0
            if edge(m,e).point > N push!(M, edge(m,e).point)  end
            e = edge(m,e).next
        end
        split_face!(m, f, M[1], M[3] )
        nf = nbf(m)
        P = (m.points[:,M[1]]+m.points[:,M[3]])/2.0
        p = push_vertex!(m, P)
        ne = nbe(m)
        split_edge!(m, ne, p)
        split_face!(m,  f,  p, M[2])
        split_face!(m, nf,  p, M[4])
    end
end


function glue_edge!(m::HMesh, i::Int64, j::Int64)
    m.edges[i].opp=j
    m.edges[j].opp=i
end

#----------------------------------------------------------------------
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


"""
    Array of arrays E[i] of edges in Counter-Clock-Wise order, which are
    adjacent to the edge of index i, strating from the boundary edge if
    it exists.
"""
function ccw_edges(m::HMesh)

    M = fill(nbe(m)+1, nbv(m))

    for (e,i) in zip(m.edges, 1:nbe(m))
        if i<M[e.point] || opp(m,i) == 0
            M[e.point] = i
        end
    end

    E = fill(Int64[], nbv(m))
    for i in 1:nbv(m)
        if M[i]<= nbe(m)
            E[i] = ccw_edges(m, M[i])
        else
            E[i] = Int64[]
        end
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
