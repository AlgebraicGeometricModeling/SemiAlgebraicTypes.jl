export sample, mesh, polar


"""
Sample the parametric curve f: u -> [x,y,z] for u in the interval X.
```
U = sample(u->[u,sin(u^2),cos(2*u)], 0.0 => 2.0*pi, 1000)
```
"""
function sample(f::Function, X::Pair, N::Int=100, dim::Int=3; args...)
    rx = LinRange(X.first,X.second,N)

    C = fill(0.0, dim, N)
    
    for (x,i) in zip(rx,1:N)
        C[:,i] = f(x)
    end
    return C
end


"""
Mesh of the parametric curve f: u -> [x(u),y(u),z(u)] for u in the interval U.
```
c = mesh(u->[u,sin(u^2),cos(2*u)], 0.0 => 2.0*pi, 1000; field=DistField(0.0,0.0,0.0))
```
"""
function mesh(f::Function, X::Pair, N::Int=100, dim::Int=3; args...)
    C = sample(f,X,N,dim)

    return mesh(C, [collect(1:N)], Vector{Int}[])
end


"""
Matrix of points of the parametric surface f: (u,v) -> [x(u,v),y(u,v),z(u,v)] for u in the interval U, v in the interval V.
**Example**
```
sample((u,v)->[u,v,cos(2*u*v)], 0.0 => 2.0, -pi => pi)
```
"""
function sample(f::Function, X::Pair, Y::Pair, N::Int=100, dim:: Int=3)
    rx = LinRange(X.first,X.second,N)
    ry = LinRange(Y.first,Y.second,N)

    S = fill(0.0,dim,N*N)
    for (x,i) in zip(rx,1:N)
        for (y,j) in zip(ry,1:N)
            S[:,(j-1)*N+i]= f(x,y)
        end
    end

    return S
end


"""
Mesh of the parametric surface f: (u,v) -> [x,y,z] for u in the interval U, v in the interval V.
**Example**
```
mesh((u,v)->[u,v,cos(2*u*v)], 0.0 => 2.0, -pi => pi, field=DistField(0.0,0.0,0.0))
```
"""
function mesh(f::Function, X::Pair, Y::Pair, N::Int=100, dim::Int=3; args...)
    P = sample(f,X,Y,N,dim)
    F = [[(i-1)*N+(j-1)+1, (i-1)*N+(j)+1, (i)*N+(j)+1, (i)*N+j] for i in 1:N-1 for j in 1:N-1]

    m = mesh(P,Vector{Int}[],F)
    for arg in args
        m[arg[1]]=arg[2]
    end
    return m
end




"""
Mesh of the graph of the radius function r = f(x,y,z) on the unitary sphere.
```
polar((x,y,z)->cos(x*y*z+1.0), 200, field=DistField())
```
"""
function polar(f::Function, N::Int64=50; args...)
    rx = LinRange(0.0, 2*pi, N)
    ry = LinRange(-pi/2, pi/2, N)
    m  = mesh(Float64)

    for x in rx
        for y in ry
            v = [cos(x)*cos(y), sin(x)*cos(y), sin(y)]
            v *= f(v[1], v[2], v[3])
            push_vertex!(m, v)
        end
    end
    for i in 1:N-1
        for j in 1:N-1
            push_face!(m,[(i)*N+j, (i)*N+(j)+1, (i-1)*N+(j)+1, (i-1)*N+(j-1)+1 ])
            #push_face!(m,[ (i-1)*N+(j-1)+1, (i-1)*N+(j)+1, (i)*N+(j)+1, (i)*N+j ])
        end
    end
    for arg in args
        m[arg[1]]=arg[2]
    end
    return m
end

