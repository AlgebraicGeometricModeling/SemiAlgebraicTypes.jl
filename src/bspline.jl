#
# Code adapted from https://github.com/TheBB/NURBS.jl package.
#
export BSplineBasis, BSplineFunction1D, BSplineFunction2D, domain, supported

type BSplineBasis 

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
        BSplineBasis(linspace(lft, rgt, elements+1), order)
end

Base.length(b::BSplineBasis) = length(b.knots) - b.order
Base.size(b::BSplineBasis) = (length(b),)
Base.getindex(b::BSplineBasis, i) = BSpline(b, i)

nderivs(b::BSplineBasis) = b.order - 1

domain(b::BSplineBasis) = (b.knots[1] => b.knots[end])
degree(b::BSplineBasis) = b.order - 1

function supported{T<:Real}(b::BSplineBasis, pt::T)
    kidx = b.order - 1 + searchsorted(b.knots[b.order:end], pt).stop
    stop = b.knots[kidx] == b.knots[end] ? kidx - b.order : kidx
    stop - b.order + 1 : stop
end

function supported{T<:Real}(b::BSplineBasis, pts::Vector{T})
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

function eval{T<:Real}(b::BSplineBasis, t::T)
    rng = supported(b, t)
    
    # Basis values of order 1 (piecewise constants)
    bvals = zeros(Float64, b.order)
    bvals[end] = 1.0

    const p = b.order
    const bi = rng.start + p

    # Order increment
    for k in 0:p-2
        @bs_er_scale bvals[p-k:end] b.knots bi k
        for (i, kp, kn) in zip(p-k-1:p-1, b.knots[bi-k-2:bi-2], b.knots[bi:bi+k])
            bvals[i] *= (t - kp)
            bvals[i] += bvals[i+1] * (kn - t)
        end
        bvals[end] *= (t - b.knots[bi-1])
    end

    bvals, rng
end

#----------------------------------------------------------------------
type BSplineFunction1D
    points::Array{Float64,2}
    basis::BSplineBasis

    function BSplineFunction1D(points, knots, order, extend=true)
        new(points, BSplineBasis(knots,order,extend))
    end

     function BSplineFunction1D(points, bs::BSplineBasis)
        new(points, bs)
    end
end

function (f::BSplineFunction1D){T<:Real}(t::T)
    vals,rng = eval(f.basis,t)
    
    sum(f.points[:,r]*vals[i] for (r,i) in zip(rng,1:length(vals)))
end

domain(f::BSplineFunction1D) = domain(f.basis)

#----------------------------------------------------------------------
type BSplineFunction2D <: Function
    points::Array{Float64,3}
    basis1::BSplineBasis
    basis2::BSplineBasis

    function BSplineFunction2D(points, bs1::BSplineBasis, bs2::BSplineBasis)
        new(points,bs1,bs2)
    end
end

function (f::BSplineFunction2D){T<:Real}(u::T,v::T)
    v1,rng1 = eval(f.basis1,u)
    v2,rng2 = eval(f.basis2,v)
    sum(f.points[:,r1,r2]*v1[i1]*v2[i2] for (r1,i1) in zip(rng1,1:length(v1)),  (r2,i2) in zip(rng2,1:length(v2)))
end

