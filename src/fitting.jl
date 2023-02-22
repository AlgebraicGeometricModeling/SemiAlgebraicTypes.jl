export fitting

function fitting_matrix(P, U, B1, B2)

    n1 = length(B1)
    n2 = length(B2)

    A = spzeros(n1*n2,size(U,2))

    for k in 1:size(U,2)

        p = U[:,k]
        b1, r1 = eval_rng(B1,p[1],0)
        b2, r2 = eval_rng(B2,p[2],0)

        for (i,s) in zip(r1,b1), (j,t) in zip(r2, b2)
            A[i+n1*(j-1),k] = s*t
        end
    end

#    P = hcat(U',P')
    return A*A', A*P'

end


function laplacian_matrix(n1, n2)
    A = spzeros(n1*n2, n1*n2)
    k = 1
    for i in 2:n1-1
        for j in 2:n2-1
            A[k,idx(n1,i,j)] = 1
            A[k,idx(n1,i-1,j)] = -1/4
            A[k,idx(n1,i+1,j)] = -1/4
            A[k,idx(n1,i,j-1)] = -1/4
            A[k,idx(n1,i,j+1)] = -1/4
            k+=1
        end
    end
    w=2
    for i in 2:n1-1
        A[k,idx(n1,i,1)]   = 1*w
        A[k,idx(n1,i-1,1)] = -1/2*w
        A[k,idx(n1,i+1,1)] = -1/2*w
        k+=1

        A[k,idx(n1,i,n2)]   = 1*w
        A[k,idx(n1,i-1,n2)] = -1/2*w
        A[k,idx(n1,i+1,n2)] = -1/2*w
        k+=1
    end
          
    for j in 2:n2-1
        A[k,idx(n1,1,j)] = 1*w
        A[k,idx(n1,1,j-1)] = -1/2*w
        A[k,idx(n1,1,j+1)] = -1/2*w
        k+=1

        A[k,idx(n1,n1,j)] = 1*w
        A[k,idx(n1,n1,j-1)] = -1/2*w
        A[k,idx(n1,n1,j+1)] = -1/2*w
        k+=1
    end
    
    return A'*A
end

"""
    fitting(P::Matrix, U::Matrix, B1::BSplineBasis, B2::BSplineBasis, ω=1.e-2)

 - `P` dxN matrix of points where d is the dimension and N the number of points
 - `U` matrix of (u1,u2) parameters
 - `B1`, `B2` bases of the bspline functions in u1, resp. u2.
 - `ω` (optional) weight of the Laplacian regularisation

Compute a tensor-product b-spline function fiiting the points P, with the parameters U
"""
function fitting(P::Matrix, U::Matrix, B1, B2, ω=1.e-2)
    A, B = fitting_matrix(P, U, B1, B2)
    H = laplacian_matrix(length(B1), length(B2))

    A = A + ω*H
    ctr = A\B

    m1 = length(B1)
    m2 = length(B2)

    local points = fill(0.,3,m1,m2)
    for i in 1:m1
        for j in 1:m2
            points[:, i, j] =  ctr[i+ m1*(j-1),:]
        end
    end
    
    return BSplineSurface(points, B1, B2)
    
end


