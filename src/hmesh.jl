export HEdge, copy, HMesh, hmesh, nbv, nbe, nbf, point, edge, hedge, face,
    point_of, ptidx_of, face_of,
    point_id,
    push_vertex!, push_edge!, push_face!,
    split_edge!, set_face!, split_face!, glue_edge!, length_face,
    next, prev, opp, face, ccw_edges, edges_on_face, minimal_edges,
    subdivide_middle!,
    cc_subdivide, cc_subdivide!

import Base: getindex, setindex!, print

mutable struct HEdge
    point::Int64
    nxt::Int64
    prev::Int64
    opp::Int64
    face::Int64
    
    function HEdge()
        new(0,0,0,0,0)
    end

    function HEdge(v::Int64, n::Int64, p::Int64, o::Int64, f::Int64)
        new(v,n,p,o,f,s)
    end

    function HEdge(e::HEdge)
        new(e.point,e.nxt,e.prev,e.opp,e.face)
    end

    function copy(e::HEdge)
        new(e.point,e.nxt,e.prev,e.opp,e.face)
    end

end

mutable struct HMesh
    points::Matrix{Float64}
    edges ::Vector{HEdge}
    faces ::Vector{Int64}
    normals::Matrix{Float64}
    ccw_e  ::Vector{Vector{Int64}}
    esingular::Vector{Int64}
    attr  ::Dict{Symbol,Any}

    function HMesh()
        new(Matrix{Float64}(undef,3,0), HEdge[], Int64[], Matrix{Float64}(undef,3,0), Vector{Vector{Int64}}(undef,0), Vector{Int64}(undef,0), Dict{Symbol,Any}())
    end

    function HMesh(pts::AbstractArray{Float64,2},
                   e::Vector{HEdge},
                   f::Vector{Vector{Int64}},
                   normals::Matrix{Float64},
                   esingular::Vector{Int64},
                   attr::Dict{Symbol,Any})
        new(pts,e,f,normals,Vector{Vector{Int64}}(undef,0),esingular,attr)
    end
end

"""
    hmesh(P::AbstractArray{Float64,2}, F::Vector{Vector{Int64}},N::Matrix{Float64}; args...)

 -  P matrix of points
 -  F array of faces
 -  N (optional) matrix of normals 

 Build a HMesh from the array of points and array of faces
"""
function hmesh(P::AbstractArray{Float64,2}, E::Vector{Vector{Int64}}, F::Vector{Vector{Int64}},  N::Matrix{Float64}=Matrix{Float64}(undef,3,0); args...)
    msh = HMesh()
    msh.points = P
    msh.normals = N
    msh.esingular = Vector{Int64}(undef,0)
    HE = Dict{Pair{Int64,Int64},Int64}()
    for f in F
        ne = nbe(msh)
        push_face!(msh,f) #f[1],f[2],f[3],f[4])
        sf = length(f)
        for i in 1:sf
            if f[i]< f[i%sf+1]
                l = f[i]; u = f[i%sf+1]
            else
                u = f[i]; l = f[i%sf+1]
            end
     
            e = get(HE, l=>u, 0)
            if e==0
                HE[l=>u] = ne+i
            else
                glue_edge!(msh, e, ne+i)
            end
        end
    end
    #println("$HE")
    for e in E
        he = get(HE, e[1]=>e[2], nothing)
        if he != nothing
            push!(msh.esingular, he)
            if (op = opp(msh, he)) != 0
                push!(msh.esingular, op)
            end
        end
        he = get(HE, e[2]=>e[1], nothing)
        if he != nothing
            push!(msh.esingular, he)
            if (op = opp(msh, he)) != 0
                push!(msh.esingular, op)
            end
        end
    end
    for arg in args msh[string(arg[1])]=arg[2] end
    return msh
end

function hmesh(m::Mesh{Float64})
    hmesh(m.points, m.edges, m.faces, m.normals)
end

function Base.getindex(m::HMesh, s::Symbol)
    get(m.attr, s, 0)
end

function setindex!(m::HMesh, v, s::Symbol)
    m.attr[s] = v
end

nbv(m::HMesh) = size(m.points,2)
nbe(m::HMesh) = length(m.edges)
nbf(m::HMesh) = length(m.faces)

function push_vertex!(m::HMesh, v::Vector{Float64})
    m.points= hcat(m.points,v)
    return nbv(m)
end

function push_edge!(m::HMesh, e::HEdge)
    push!(m.edges,e)
    return nbe(m)
end

function point(m::HMesh, i) m.points[:,i] end
function edge(m::HMesh, i) m.edges[i] end
function hedge(m::HMesh, i) m.edges[i] end
function face(m::HMesh, i) m.faces[i] end

#function vertex_of(m::HMesh, i) m.edges[i].point end

function point_of(m::HMesh, i) m.points[:, m.edges[i].point] end
function ptidx_of(m::HMesh, e) m.edges[e].point end

function point_id(m::HMesh, e) m.edges[e].point end

function face_of(m::HMesh, e::Int64)
    edge(m,e).face
end

function length_face(msh::HMesh, f)
    ef = msh.faces[f]
    c = 1
    e = edge(msh,ef).nxt
    while e != ef
        e = edge(msh,e).nxt
        c +=1
    end
    return c
end

function next(m::HMesh, e::Int64)
    m.edges[e].nxt
end

function opp(m::HMesh, e::Int64)
    m.edges[e].opp
end

function prev(m::HMesh, e::Int64)
    edge(m,e).prev
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
        e.nxt = ne+i%length(F)+1
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
    e1 = HEdge(); e1.point=p1; e1.nxt=ne+2; e1.prev=ne+4; e1.face=f
    e2 = HEdge(); e2.point=p2; e2.nxt=ne+3; e2.prev=ne+1; e2.face=f
    e3 = HEdge(); e3.point=p3; e3.nxt=ne+4; e3.prev=ne+2; e3.face=f
    e4 = HEdge(); e4.point=p4; e4.nxt=ne+1; e4.prev=ne+3; e4.face=f
    push_edge!(m,e1)
    push_edge!(m,e2)
    push_edge!(m,e3)
    push_edge!(m,e4)
    push!(m.faces, ne+1);
    return f
end

export glue_edges!

function glue_edges!(m::HMesh, e1::Int64, e2::Int64)
    m.edges[e1].opp = e2
    m.edges[e2].opp = e1    
end

#----------------------------------------------------------------------
export is_border, is_singular, edge_of_face

"""
    Test if the edge is on the boundary of the surface (i.e. opp==0 ?)
"""
function is_border(m::HMesh, e::Int64)
    @assert e>0
    return  opp(m,e)==0
end

function is_singular(msh::HMesh,e::Int64)
    return is_border(msh,e) || (e in msh.esingular)
end

"""
    Reference half-edge defining the face.
"""
function edge_of_face(m::HMesh, f::Int64)
    return m.faces[f]
end


"""
  Insert the point of index p in the edge e and its opposite if it exists.
  A new edge is added in front of the edge e, as well as in front of 
  its opposite, if it exists.
"""
function split_edge!(msh, e, p)

    #println("--- split ", e, " ", edge(msh,e), " at ", p)
    o = opp(msh,e)
    
    NE = HEdge(edge(msh,e))
    NE.point = p
    NE.prev  = e


    ne = push_edge!(msh,NE)

    if (e in msh.esingular)
        push!(msh.esingular,ne)
        #println(".... ",length(msh.esingular)
    end
    
    edge(msh,edge(msh,e).nxt).prev = ne
    edge(msh,e).nxt = ne

    if o != 0

        NO = HEdge(edge(msh,o))
        NO.point = p
        NO.prev = o
        
        no = push_edge!(msh,NO)

        if e in msh.esingular
            push!(msh.esingular,no)
    
        end

        edge(msh,edge(msh,o).nxt).prev = no
        edge(msh,o).nxt = no

        edge(msh,no).opp = e
        edge(msh,e).opp = no
        
        edge(msh,ne).opp = o
        edge(msh,o).opp = ne

        edge(msh,edge(msh,no).prev).nxt = no

    end
end

function set_face!(msh, e0, f)
    e = e0
    edge(msh,e).face = f
    e = edge(msh,e0).nxt
    while e != e0
        edge(msh,e).face = f
        e = edge(msh,e).nxt
    end
end


"""
Split the face f by inserting the edge between the vertices v1 and v2.
A new face is added at the end of the array of faces.
"""
function split_face!(m, fidx, v1,  v2)

    ef = m.faces[fidx]
    #println(">>>>>>  face init ", length_face(m,fidx))
    
    e1 = ef
    p  = edge(m,e1).point
    while p != v1 
        e1 = edge(m,e1).nxt
        (e1 == ef) && break   
        p  = edge(m,e1).point
        # println("  e1  ", e1)
    end
    # if(p!= v1)
    #     println(">>> e1 ", edge(m,e1).point," ",v1, " ", p)
    # end

    e2 = e1
    p = edge(m,e2).point
    while p != v2
        e2 = edge(m,e2).nxt
        (e2 == e1) && break
        p  = edge(m,e2).point
    end
    # if(p!= v2)
    #     println(">>> e2 ", edge(m,e2).point," ",v2, " ", p)
    # end


    E1 = HEdge(edge(m,e1))
    E2 = HEdge(edge(m,e2))

    E1.nxt = e2
    E2.nxt = e1

    E1.face = nbf(m)+1
    E2.face = fidx

    ne1 = push_edge!(m,E1)
    ne2 = push_edge!(m,E2)

    edge(m,ne1).opp = ne2
    edge(m,ne2).opp = ne1

    edge(m,edge(m,e1).prev).nxt = ne1
    edge(m,edge(m,e2).prev).nxt = ne2

    edge(m,e1).prev = ne2
    edge(m,e2).prev = ne1

    nf = push_face!(m,ne1)

    #println(">>>>>>  face ", length_face(m,fidx), "  ", length_face(m,nf))
    m.faces[fidx] = ne1
    m.faces[nf]   = ne2

    set_face!(m,ne1, fidx)
    set_face!(m,ne2, nf)
    #println("split face ", fidx)
    return nf 
end
"""
    subdivide_middle!(msh::HMesh)

Subdivide each face by inserting the middle of the edges and the middle of the faces.
"""
function subdivide_middle!(m::HMesh)
    N = nbv(m)
    E = nbe(m)
    for e in 1:E
        p1 = edge(m,e).point
        p2 = edge(m,edge(m,e).nxt).point

        if p1 <= N && p2 <= N
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
        e = edge(m,e0).nxt
        while e != e0
            if edge(m,e).point > N push!(M, edge(m,e).point)  end
            e = edge(m,e).nxt
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


#----------------------------------------------------------------------
function glue_edge!(m::HMesh, i::Int64, j::Int64)
    m.edges[i].opp=j
    m.edges[j].opp=i
end

#----------------------------------------------------------------------
function ccw_edges(m::HMesh, e0::Int64)

    E0 = Int64[e0]

    ep = prev(m,e0)
    e = opp(m,ep)
    while !is_singular(m,ep) && e != e0
        push!(E0,e)
        ep = prev(m,e)
        e  = opp(m,ep)
    end
    return E0

end

"""
    ccw_edges(m::HMesh)

Array of arrays E[i] of edges in Counter-Clock-Wise order, which are adjacent
to the edge of index i, starting from the boundary edge if it exists.
"""
function ccw_edges(m::HMesh)

    M = fill(nbe(m)+1, nbv(m))

    for (e,i) in zip(m.edges, 1:nbe(m))
        if i<M[e.point] || is_singular(m,i) # == 0
            M[e.point] = i
        end
    end

    E = fill(Int64[], nbv(m))
    for i in 1:nbv(m)
        if M[i]<= nbe(m)
            E[i] = ccw_edges(m, M[i])
            #println("---- ",E[i])
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
"""
    cc_subdivide(msh::HMesh, n::Int64 = 1)

Catmull-Clark subdivision of a Half-Edge mesh.

The mesh `msh` is replaced by the subdivided mesh, applying n times Catmull-Clark scheme.
"""
function cc_subdivide(msh::HMesh, n::Int64 = 1)
    m = copy(msh)
    cc_subdivide!(m,n)
    return m
end

function cc_subdivide(msh::Mesh, n::Int64 = 1)
    m = hmesh(msh)
    cc_subdivide!(m,n)
    return m
end


"""
    cc_subdivide!(msh::HMesh, n::Int64 = 1)

Catmull-Clark subdivision of a Half-Edge mesh.

The mesh `msh` is replaced by the subdivided mesh, applying n times Catmull-Clark scheme.
"""
function cc_subdivide!(msh::HMesh, n::Int64 = 1; verbose = false)

    #for e in msh.esingular  msh.edges[e].opp = 0 end
    
    for i in 1:n
        nv0 = nbv(msh)
        val      = fill(0, nbv(msh))
        sing_val = fill(0, nbv(msh))
        sing_edges = Dict{Int64,Int64}() #p::point -> e::a singular edge

        edges_ccw = ccw_edges(msh)
        
        # Compute valence and boundary edges
        for e in 1:nbe(msh)
            p = point_id(msh,e) 
            val[p] += 1
            if is_singular(msh, e) #|| e in msh.esingular

                sing_val[p]+=1
                sing_edges[p]=e

                if is_border(msh,e)
                    np = point_id(msh,next(msh,e))
                    sing_val[np]+=1
                end
                        
            end
        end

        verbose && println("Singular: $sing_edges")
        verbose && println("sing val: $sing_val")
        verbose && println("     val: $val")

        # Compute face points (same as before)
        ptf = fill(0, nbf(msh))
        for f in 1:nbf(msh)
            e0 = msh.faces[f]
            p = point_of(msh, e0)
            e = next(msh, e0)
            c = 1
            while e != e0
                p += point_of(msh, e)
                e = next(msh, e)
                c += 1
            end
            p /= c
            if p[2] > 3 @info("f $p") end
            ptf[f] = push_vertex!(msh, p)
        end
        
        # Compute edge points (special handling for boundary edges)
        pte = fill(0, nbe(msh))
        for e in 1:nbe(msh)
            #if pte[e] == 0
            if is_singular(msh,e)    #e in msh.esingular || o == 0
                # Treat as boundary edge: midpoint of its two endpoints
                p = (point_of(msh, e) + point_of(msh, next(msh, e))) / 2
                pte[e] = push_vertex!(msh, p)
                #@info("e   $p")
                #pte[o] = pte[e]  # Ensure both half-edges share the same point
            else
                # Regular interior edge
                p = point_of(msh, e) + point_of(msh, next(msh, e))
                p += point(msh, ptf[edge(msh, e).face])
                p += point(msh, ptf[edge(msh, opp(msh, e)).face])
                p /= 4.0
                #@info("e   $p")
                pte[e] = push_vertex!(msh, p)
            end
            #end
        end
        
        # Compute vertex points (boundary rules only affect position)
        for p in 1:nv0
            v = val[p]
            v_edges = edges_ccw[p]
            #print("... point $p ",is_sing[p])
            if val[p] == 1 || sing_val[p] >2 # == 1 #CORNER VERTEX
                verbose && println("... Corner")
                continue
            elseif haskey(sing_edges,p)  #[p] != 0 #boundary or singular vertex
                verbose && println("... Singular boundary or smooth corner")

                es = sing_edges[p]

                #println("...> $es ", opp(msh,es))

                first_e = next(msh,es)

                pe = prev(msh,es)

                c = 0
                while opp(msh,pe) != 0 && c < 20
                    pe = prev(msh,opp(msh,pe))
                    c+=1
                end
                
                last_e  = pe # prev(msh,es)

                # if !is_singular(msh, last_e)
                #    last_e = prev(msh,opp(msh,last_e))
                # end

                #println("... ", point_id(msh,first_e), "  ", point_id(msh, last_e))

                # Previously 1-4-1
                # msh.points[:, p] *= (2/3)
                # msh.points[:, p] += point_of(msh,next(msh,first_e))*(1/6)
                # msh.points[:, p] += point_of(msh,last_e)*(1/6)
                msh.points[:, p] *= (2/3)
                msh.points[:, p] += point_of(msh,first_e)*(1/6)
                msh.points[:, p] += point_of(msh,last_e)*(1/6)



            elseif !haskey(sing_edges,p) #&& !(p in v_singular) #REGULAR INNER VERTEX
                #println("... Regular $v $v_edges")
                msh.points[:, p] .*= (v-3)/v #1 - 7 / (4 * v)
                for e in v_edges
                    msh.points[:, p] += point(msh, pte[e]) * (2 / (v * v))
                    f = edge(msh, e).face
                    msh.points[:, p] += point(msh, ptf[f]) * (1 / (v * v))
                end
                #if msh.points[2, p] >3  println(".... ", msh.points[:, p]) end
            else
                @info("cc_subdivide case ???")
            end
        end

      # Split edges
      # println("-- split edges")
      spl = fill(0, nbe(msh))
      for e in 1:nbe(msh)
          o = opp(msh,e)
          if o == 0 
              spl[e] = 1
          elseif spl[o] == 0
              spl[e] = 1
          end
      end
      
      for e in 1:nbe(msh)
          if spl[e] == 1
              split_edge!(msh, e, pte[e])
          end
      end
      
      # Split faces
      # println("-- split faces")
      e = fill(0,8)
      for f in 1:nbf(msh)
          e[1] = msh.faces[f]
          for i in 2:8
              e[i] = next(msh,e[i-1])
          end
          
          p1 = point_id(msh,e[4])
          p2 = point_id(msh,e[8])
          
          split_face!(msh, f, point_id(msh,e[2]), point_id(msh,e[6]))
          
          nf = nbf(msh)

          split_edge!(msh, nbe(msh), ptf[f] )
          
          # println("---------"); check(msh); println("---------")
          
          split_face!(msh, nf,  p1, ptf[f])
          split_face!(msh,  f,  p2, ptf[f])
          
      end
    end
    return msh
end
