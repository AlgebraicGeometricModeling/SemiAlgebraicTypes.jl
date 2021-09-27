#
# Code adapted from https://github.com/TheBB/NURBS.jl package.
#

export BSplineBasis,
    BSplineFunction1D, BSplineFunction2D, BSplineFunction3D,
    BSplineCurve, BSplineSurface, BSplineVolume,
    domain, supported, eval_rng,
    mesh


mutable struct BSplineBasis

    knots::Vector{Float64}
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

function eval_rng(b::BSplineBasis, t::T, deriv::Int = 0 ) where {T<:Real}
    rng = supported(b, t)

    # Basis values of order 1 (piecewise constants)
    bvals = zeros(Float64, b.order)
    bvals[end] = 1.0

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
mutable struct BSplineFunction1D
    points::Array{Float64,2}
    basis::BSplineBasis

    function BSplineFunction1D(points, knots, order, extend=true)
        new(points, BSplineBasis(knots,order,extend))
    end

     function BSplineFunction1D(points, bs::BSplineBasis)
        new(points, bs)
    end
end

function (f::BSplineFunction1D)(t::T) where {T<:Real}
    vals,rng = eval_rng(f.basis,t)

    sum(f.points[:,r]*vals[i] for (r,i) in zip(rng,1:length(vals)))
end

domain(f::BSplineFunction1D) = domain(f.basis)

#----------------------------------------------------------------------
mutable struct BSplineFunction2D <: Function
    points::Array{Float64,3}
    basis1::BSplineBasis
    basis2::BSplineBasis

    function BSplineFunction2D(points, bs1::BSplineBasis, bs2::BSplineBasis)
        new(points,bs1,bs2)
    end
end

function (f::BSplineFunction2D)(u::T,v::T, d1=0, d2=0) where {T<:Real}
    v1, rng1 = eval_rng(f.basis1,u,d1)
    v2, rng2 = eval_rng(f.basis2,v,d2)
    sum(f.points[:,r1,r2]*v1[i1]*v2[i2]
        for (r1,i1) in zip(rng1,1:length(v1)),
            (r2,i2) in zip(rng2,1:length(v2)))
end

domain(f::BSplineFunction2D) = [domain(f.basis1),domain(f.basis2)]
#----------------------------------------------------------------------
mutable struct BSplineFunction3D <: Function
    points::Array{Float64,4}
    basis1::BSplineBasis
    basis2::BSplineBasis
    basis3::BSplineBasis

    function BSplineFunction2D(points, bs1::BSplineBasis, bs2::BSplineBasis, bs3::BSplineBasis)
        new(points,bs1,bs2,bs3)
    end
end

function (f::BSplineFunction3D)(u::T,v::T,w::T) where {T<:Real}
    v1,rng1 = eval_rng(f.basis1,u)
    v2,rng2 = eval_rng(f.basis2,v)
    v3,rng3 = eval_rng(f.basis3,w)
        sum(f.points[:,r1,r2,r3]*v1[i1]*v2[i2]*v3[i3] for (r1,i1) in zip(rng1, 1:length(v1)), (r2,i2) in zip(rng2, 1:length(v2)), (r3,i3) in zip(rng3, 1:length(v3)))
end

domain(f::BSplineFunction3D) = [domain(f.basis1),domain(f.basis2),domain(f.basis3)]
#----------------------------------------------------------------------
#----------------------------------------------------------------------
mutable struct BSplineCurve
    map ::BSplineFunction1D
    attr::Dict{Symbol,Any}

    function BSplineCurve(points, knots, order, extend=true)
        map = BSplineFunction1D(points,knots,order,extend)
        new(map, Dict{Symbol,Any}())
    end

    function BSplineCurve(points, bs::BSplineBasis; args...)
        dict =  Dict{Symbol,Any}()
        for arg in args
            dict[arg[1]]=arg[2]
        end
        new( BSplineFunction1D(points, bs), dict)
    end

    function BSplineCurve(points, bs::BSplineBasis, dict::Dict{Symbol,Any})
        new( BSplineFunction1D(points, bs), dict)
    end
end

function Base.getindex(f::BSplineCurve, s::Symbol)  get(f.attr, s, 0) end
function Base.setindex!(f::BSplineCurve, v, s::Symbol)  f.attr[s] = v end

#----------------------------------------------------------------------
mutable struct BSplineSurface
    map  ::BSplineFunction2D
    attr ::Dict{Symbol,Any}

    function BSplineSurface(points, bs1::BSplineBasis, bs2::BSplineBasis; args...)
        dict =  Dict{Symbol,Any}()
        for arg in args
            dict[arg[1]]=arg[2]
        end
        new(BSplineFunction2D(points,bs1,bs2), dict)
    end
    
    function BSplineSurface(points, bs1::BSplineBasis, bs2::BSplineBasis, dict::Dict{Symbol,Any})
        new(BSplineFunction2D(points, bs1, bs2), dict)
    end
end

function Base.getindex(f::BSplineSurface, s::Symbol)  get(f.attr, s, 0) end
function Base.setindex!(f::BSplineSurface, v, s::Symbol)  f.attr[s] = v end

#----------------------------------------------------------------------
mutable struct BSplineVolume
    map  ::BSplineFunction3D
    attr ::Dict{Symbol,Any}

    function BSplineVolume(points, bs1::BSplineBasis, bs2::BSplineBasis, bs3::BSplineBasis; args...)
        dict =  Dict{Symbol,Any}()
        for arg in args
            dict[arg[1]]=arg[2]
        end
        new(BSplineFunction3D(points,bs1,bs2,bs3), dict)
    end
    
    function BSplineVolume(points, bs1::BSplineBasis, bs2::BSplineBasis, bs3::BSplineBasis, dict::Dict{Symbol,Any})
        new(BSplineFunction3D(points, bs1, bs2, bs3), dict)
    end
end

function Base.getindex(f::BSplineVolume, s::Symbol)  get(f.attr, s, 0) end
function Base.setindex!(f::BSplineVolume, v, s::Symbol)  f.attr[s] = v end



#----------------------------------------------------------------------
function mesh(b::BSplineSurface, N::Int=50; args...)
    f = b.map
    D = domain(f)
    rx = LinRange(D[1][1],D[1][2],N)
    ry = LinRange(D[2][1],D[2][2],N) 

    f = b.map
    m = SemiAlgebraicTypes.mesh(Float64)
    for x in rx
        for y in ry
            push_vertex!(m,f(x,y))
        end
    end
    for i in 1:N-1
        for j in 1:N-1
            push_face!(m,[(i-1)*N+(j-1)+1, (i-1)*N+(j)+1, (i)*N+(j)+1, (i)*N+j])
        end
    end
    for arg in args
        m[arg[1]]=arg[2]
    end
    return m
end
