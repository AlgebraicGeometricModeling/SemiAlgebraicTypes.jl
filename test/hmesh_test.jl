using SemiAlgebraicTypes

m =  hmesh(
    [
          0.  0.  0. 
        ; 1.  0.  0. 
        ; 1.  1.  0. 
        ; 0.  1.  0.
        ; 0. -1.  0.
        ; 1  -1.  0.
    ]',
    [
        [1,2,3,4],
        [2,1,5,6]
    ]
)

v1 = push_vertex!(m, point(0.5, -0.25, 0.0))
split_edge!(m,1,v1)

v2 = push_vertex!(m, point(0.5, 1.5, 0.0))
split_edge!(m,3,v2)

split_face!(m, 1, v1, v2)

