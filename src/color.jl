export Color, DirField, dirfield, DistField, distfield

"""
Color represented by the `r`, `g`, `b` components (`Int64` between 0 and 255)  and a transparency component `t` (`Float64` between 0.0 and 1.0).
"""
mutable struct Color
    r::Int64
    g::Int64
    b::Int64
    t::Float64

    function Color(r::Int64, g::Int64, b::Int64, t::Float64=1.0)
        new(r,g,b,t)
    end
end


"""
Scalar field described by a vector `dir`. The field value at a point is obtained by taking the scalar product with the vector.
"""
mutable struct DirField
    dir::Vector{Float64}
    
    function DirField(x::Float64=1.0, y::Float64=0.0, z::Float64=0.0)
        new([x,y,z])
    end
end

"""
Scalar field described by the point `pt`. The field value at a point is obtained by computing the distance to the point `pt`.
"""
mutable struct DistField
    pt::Vector{Float64}
    function DistField(x::Float64=0.0, y::Float64=0.0, z::Float64=0.0)
        new([x,y,z])
    end
end

