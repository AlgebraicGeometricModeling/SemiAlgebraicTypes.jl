export Color
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
