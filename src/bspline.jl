#
# Code adapted from https://github.com/TheBB/NURBS.jl package.
#

export BSplineBasis,
    BSplineCurve, BSplineSurface, BSplineVolume,
#    BSplineCCurve, BSplineSSurface, BSplineVVolume,
    domain, supported, eval_rng, knots,
    mesh


mutable struct BSplineBasis

    knots::Vector
    order::Int

    function BSplineBasis(knots, order, extend=true)

        for (kn, kp) in zip(knots[2:end], knots[1:end-1])
            @assert(kn >= kp, "Knot vector must be nondecreasing")
        end

        if extend
            knots = append!(append!( fill(knots[1], order-1), knots), fill(knots[end], order-1))
        else
            for d in 1:order-1
                @assert(knots[1+d] == knots[1] && knots[end-d] == knots[end],
                        "Expected $order repeated knots on either end")
            end
        end

        new(knots, order)
    end

    BSplineBasis(lft::Real, rgt::Real, elements::Int, order::Int) =
        BSplineBasis(LinRange(lft, rgt, elements+1), order)
end

Base.length(b::BSplineBasis) = length(b.knots) - b.order
Base.size(b::BSplineBasis) = (length(b),)
Base.getindex(b::BSplineBasis, i) = BSpline(b, i)

nderivs(b::BSplineBasis) = b.order - 1

domain(b::BSplineBasis) = (b.knots[1] => b.knots[end])
degree(b::BSplineBasis) = b.order - 1

function supported(b::BSplineBasis, pt::T) where {T<:Real}
    kidx = b.order - 1 + searchsorted(b.knots[b.order:end], pt).stop
    stop = b.knots[kidx] == b.knots[end] ? kidx - b.order : kidx
    stop - b.order + 1 : stop
end

function supported(b::BSplineBasis, pts::Vector{T}) where {T<:Real}
    (min, max) = extrema(pts)
    @assert(min in domain(b) && max in domain(b), "pts outside the domain of the basis")

    idxs = zeros(Int, length(pts))

    if !issorted(pts)
        for (i, pt) in enumerate(pts)
            idxs[i] = supported(b, pt).stop
        end
    else
        kidx = b.order
        for (i, pt) in enumerate(pts)
            kidx = kidx - 1 + searchsorted(b.knots[kidx:end], pt).stop
            idxs[i] = b.knots[kidx] == b.knots[end] ? kidx - b.order : kidx
        end
    end

    imap(groupby(enumerate(idxs), i -> i[2])) do i
        (pts[i[1][1]:i[end][1]], i[1][2] - b.order + 1 : i[1][2])
    end
end

macro bs_er_scale(bvals, knots, mid, num)
    :($bvals ./= $knots[$mid:$mid+$num] - $knots[$mid-$num-1:$mid-1])
end

"""

    knots(d,N,μ,a,b) 


Compute the knot sequence of degree d, of multiplicity μ with N equally spaced subintervals between a and b.


The default values are  μ=1, a=1.0, b=1.0.
"""
function knots(d,N, μ=1, a=0.0, b=1.0)
    kn = [a]

    for i in 1:d push!(kn,a) end
    for i in 1:N-1
        for k in 1:μ
            push!(kn, a + (b-a)*(i//N))
        end
    end
    for i in 1:(d+1) push!(kn,b) end
    return kn
end

function eval_rng(b::BSplineBasis, t::T, deriv::Int = 0 ) where {T<:Real}
    rng = supported(b, t)

    # Basis values of order 1 (piecewise constants)
    bvals = zeros(typeof(b.knots[1]), b.order)
    bvals[end] = 1

    p = b.order
    bi = rng.start + p

    # Order increment
    for k in 0:p-deriv-2
        #@bs_er_scale bvals[p-k:end] b.knots bi k
        bvals[p-k:end] ./= b.knots[bi:bi+k] - b.knots[bi-k-1:bi-1]
        for (i, kp, kn) in zip(p-k-1:p-1, b.knots[bi-k-2:bi-2], b.knots[bi:bi+k])
            bvals[i] *= (t - kp)
            bvals[i] += bvals[i+1] * (kn - t)
        end
        bvals[end] *= (t - b.knots[bi-1])
    end

    # Differentiation
    for k = p-deriv-1:p-2
        #@bs_er_scale bvals[p-k:end] b.knots bi k
        bvals[p-k:end] ./= b.knots[bi:bi+k] - b.knots[bi-k-1:bi-1]
        bvals[1:end-1] = - diff(bvals)
        bvals *= k + 1
    end

    bvals, rng
end


#----------------------------------------------------------------------
"""
 Bspline curve with a matrix dxm of control points `points` and a `basis` . 
"""
mutable struct BSplineCurve <: Function
    points::Array{Float64,2}
    basis::BSplineBasis
    attr ::Dict{Symbol,Any}

    function BSplineCurve(points, knots, order, extend=true)
        new(points, BSplineBasis(knots,order,extend),Dict{Symbol,Any}())
    end

     function BSplineCurve(points, bs::BSplineBasis)
        new(points, bs,Dict{Symbol,Any}())
    end
end

function (f::BSplineCurve)(t::T) where {T<:Real}
    vals,rng = eval_rng(f.basis,t)

    sum(f.points[:,r]*vals[i] for (r,i) in zip(rng,1:length(vals)))
end

domain(f::BSplineCurve) = domain(f.basis)

function Base.getindex(f::BSplineCurve, s::Symbol)  get(f.attr, s, 0) end
function Base.setindex!(f::BSplineCurve, v, s::Symbol)  f.attr[s] = v end

#----------------------------------------------------------------------
"""
Bspline surface with a tensor dxm1xm2 of control points `points` and bases `basis1, basis2` .
"""
mutable struct BSplineSurface <: Function
    points::Array{Float64,3}
    basis1::BSplineBasis
    basis2::BSplineBasis
    attr ::Dict{Symbol,Any}

    function BSplineSurface(points, bs1::BSplineBasis, bs2::BSplineBasis)
        new(points,bs1,bs2,Dict{Symbol,Any}())
    end
end

function (f::BSplineSurface)(u::T,v::T, d1=0, d2=0) where {T<:Real}
    v1, rng1 = eval_rng(f.basis1,u,d1)
    v2, rng2 = eval_rng(f.basis2,v,d2)
    sum(f.points[:,r1,r2]*v1[i1]*v2[i2]
        for (r1,i1) in zip(rng1,1:length(v1)),
            (r2,i2) in zip(rng2,1:length(v2)))
end

domain(f::BSplineSurface) = [domain(f.basis1),domain(f.basis2)]

function Base.getindex(f::BSplineSurface, s::Symbol)  get(f.attr, s, 0) end
function Base.setindex!(f::BSplineSurface, v, s::Symbol)  f.attr[s] = v end

#----------------------------------------------------------------------
"""
Bspline volume with a tensor dxm1xm2xm3 of control points `points` and bases `basis1, basis2, basis3`.
"""
mutable struct BSplineVolume <: Function
    points::Array{Float64,4}
    basis1::BSplineBasis
    basis2::BSplineBasis
    basis3::BSplineBasis
    attr ::Dict{Symbol,Any}
    
    function BSplineVolume(points, bs1::BSplineBasis, bs2::BSplineBasis, bs3::BSplineBasis)
        new(points,bs1,bs2,bs3,Dict{Symbol,Any}())
    end
end

function (f::BSplineVolume)(u::T,v::T,w::T) where {T<:Real}
    v1,rng1 = eval_rng(f.basis1,u)
    v2,rng2 = eval_rng(f.basis2,v)
    v3,rng3 = eval_rng(f.basis3,w)
        sum(f.points[:,r1,r2,r3]*v1[i1]*v2[i2]*v3[i3] for (r1,i1) in zip(rng1, 1:length(v1)), (r2,i2) in zip(rng2, 1:length(v2)), (r3,i3) in zip(rng3, 1:length(v3)))
end

domain(f::BSplineVolume) = [domain(f.basis1),domain(f.basis2),domain(f.basis3)]


function Base.getindex(f::BSplineVolume, s::Symbol)  get(f.attr, s, 0) end
function Base.setindex!(f::BSplineVolume, v, s::Symbol)  f.attr[s] = v end

#----------------------------------------------------------------------
#=

#----------------------------------------------------------------------
mutable struct BSplineCCurve
    map ::BSplineCurve
    attr::Dict{Symbol,Any}

    function BSplineCCurve(points, knots, order, extend=true)
        map = BSplineCurve(points,knots,order,extend)
        new(map, Dict{Symbol,Any}())
    end

    function BSplineCCurve(points, bs::BSplineBasis; args...)
        dict =  Dict{Symbol,Any}()
        for arg in args
            dict[arg[1]]=arg[2]
        end
        new( BSplineCurve(points, bs), dict)
    end

    function BSplineCCurve(points, bs::BSplineBasis, dict::Dict{Symbol,Any})
        new( BSplineCurve(points, bs), dict)
    end
end

function Base.getindex(f::BSplineCCurve, s::Symbol)  get(f.attr, s, 0) end
function Base.setindex!(f::BSplineCCurve, v, s::Symbol)  f.attr[s] = v end

function (f::BSplineCCurve)(u::T) where {T<:Real}
    return f.map(u)
end

function (f::BSplineCCurve)(u::Vector{T}) where {T<:Real}
    return f.map(u[1])
end

#----------------------------------------------------------------------
mutable struct BSplineSSurface
    map  ::BSplineSurface
    attr ::Dict{Symbol,Any}

    function BSplineSSurface(points, bs1::BSplineBasis, bs2::BSplineBasis; args...)
        dict =  Dict{Symbol,Any}()
        for arg in args
            dict[arg[1]]=arg[2]
        end
        new(BSplineSurface(points,bs1,bs2), dict)
    end
    
    function BSplineSSurface(points, bs1::BSplineBasis, bs2::BSplineBasis, dict::Dict{Symbol,Any})
        new(BSplineSurface(points, bs1, bs2), dict)
    end
end

function Base.getindex(f::BSplineSSurface, s::Symbol)  get(f.attr, s, 0) end
function Base.setindex!(f::BSplineSSurface, v, s::Symbol)  f.attr[s] = v end

function (f::BSplineSSurface)(u::T, v::T) where {T<:Real}
    return f.map(u,v)
end

function (f::BSplineSSurface)(P::Vector{T}) where {T<:Real}
    return f.map(P[1],P[2])
end
#----------------------------------------------------------------------
mutable struct BSplineVVolume
    map  ::BSplineVolume
    attr ::Dict{Symbol,Any}

    function BSplineVVolume(points, bs1::BSplineBasis, bs2::BSplineBasis, bs3::BSplineBasis; args...)
        dict =  Dict{Symbol,Any}()
        for arg in args
            dict[arg[1]]=arg[2]
        end
        new(BSplineVolume(points,bs1,bs2,bs3), dict)
    end
    
    function BSplineVVolume(points, bs1::BSplineBasis, bs2::BSplineBasis, bs3::BSplineBasis, dict::Dict{Symbol,Any})
        new(BSplineVolume(points, bs1, bs2, bs3), dict)
    end
end

function Base.getindex(f::BSplineVVolume, s::Symbol)  get(f.attr, s, 0) end
function Base.setindex!(f::BSplineVVolume, v, s::Symbol)  f.attr[s] = v end

function (f::BSplineVVolume)(u::T, v::T, w::T) where {T<:Real}
    return f.map(u,v,w)
end

function (f::BSplineVVolume)(P::Vector{T}) where {T<:Real}
    return f.map(P[1],P[2],P[3])
end
=#


#----------------------------------------------------------------------
function mesh(s::BSplineSurface, N::Int=50; args...)
    D = domain(s)

    return mesh(s, D[1], D[2], N)
end
