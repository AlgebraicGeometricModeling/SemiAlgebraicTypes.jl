    export objread
#----------------------------------------------------------------------
"""
Read an obj file and ouput a mesh.
```
objread("file.obj")
```
"""
function _objread(file::String)
    io = open(file)
    m = mesh(Float64)
    for txt in eachline(io)
        l = split(txt, " ");
        if l[1] == "v"
        
            pt = Float64[]
            s = 0
            for i in 2:length(l)
                if length(l[i])>0 && !startswith(l[i]," ") && s<3
                    push!(pt,parse(Float64,l[i]))
                    

                    s+=1

                end
            end
            push_vertex!(m,pt)
            
        elseif l[1] == "vn"
            
            pt = Float64[]
            s = 0
            for i in 2:length(l)
                if length(l[i])>0 && !startswith(l[i]," ") && s<3
                    push!(pt,parse(Float64,l[i]))
                    

                    s+=1

                end
            end
           push_normal!(m,pt)
        elseif l[1] == "f"
            f = Int64[]
            for i in 2:length(l)

                if length(l[i])>0 && !startswith(l[i]," ") 
                    push!(f, parse(Int64, split(split(l[i],"//")[1],"/")[1]  ))
                    

                end
            end
            push_face!(m,f)
        end

    end
    close(io)
    m
end

#----------------------------------------------------------------------
"""
Read an obj file and ouput a mesh.
```
objread("file.obj")
```
"""
function objread(file::String)
    if !endswith(file,".obj")
        file = file*".obj"
    end
    
    io = open(file)
    m  = mesh(Float64)

    for txt in eachline(io)

        if startswith(txt, "v ")
            l = split(txt);
            pt = Float64[]
            for i in 2:length(l)
                push!(pt, parse(Float64, l[i]))
            end
            push_vertex!(m,pt)
        elseif startswith(txt, "f ")
            l = split(txt);
            f = Int64[]
            for i in 2:length(l)
                if length(l[i])>0 && !startswith(l[i]," ")
                    push!(f, parse(Int64, split(l[i],"/")[1] ))
                end
            end
            push_face!(m,f)
        elseif startswith(txt, "o")
            
        end
    end
    close(io)
    return m
end



#----------------------------------------------------------------------
export objdata
"""
Read the obj data in the 'file' of the data repository.
```
m = objdata("cube.obj")
```

"""
function objdata(file::String)
    m = objread(joinpath(SAT[:pkgdir],"data/obj",file))
end


export objprint
"""
Print the mesh 'msh' in a 'file' in OBJ format.
```
m = objprint(msh, "file.obj")
```
The file name is optional. The default file is "tmp.obj". 

"""
function objprint(msh::HMesh, file="tmp.obj")
    io = open(file,"w")
    print(io,"OBJ\n")
    println(io, nbv(msh)," ",nbf(msh), " ", div(length(msh.esingular)+1,2))
    for p in 1:nbv(msh)
        println(io, point(msh,p))
    end
    for f in 1:nbf(msh)
        E = edges_on_face(msh,f)
        P = map(t-> point_id(msh,t)-1,E)
        println(io,length(P)," ",P)
    end
    for e in msh.esingular
        p1 = point_id(msh,e)
        p2 = point_id(msh, next(msh,e))
        if p1 < p2
            println(io,p1-1," ",p2-1)
        end
    end
    close(io)
end

function objprint(msh::Mesh, file="tmp.obj")
    io = open(file,"w")
    print(io,"OBJ \n")
    println(io, nbv(msh)," ",nbf(msh), " ", nbe(msh))
    for i in 1:nbv(msh)
        println(io, msh.points[:,i])
    end
    for i in 1:nbf(msh)
        F = msh.faces[i]
        P = map(t-> t-1,F)
        println(io,length(P)," ",P)
    end

    for i in 1:nbe(msh)
        e = msh.edges[i]
        println(io,e[1]-1," ",e[2]-1)
    end
    close(io)
end

export objprint
"""
Print a mesh in an obj file.
```
objprint(m, "file.obj")
```
"""
function _objprint(m,file)
    io = open(file,"w")
    
    for i in 1:length(m.points[1,:])
        print(io,"v ",m.points[:,i],"\n")
    end
    
    for i in 1:length(m.faces)
        print(io,"f ",m.faces[i],"\n")
    end
    close(io)
end
