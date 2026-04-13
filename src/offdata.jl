export offread
#----------------------------------------------------------------------
"""
Read an off file and ouput a mesh.
```
offread("file.off")
```
"""
function offread(file::String)
    if !endswith(file,".off")
        file = file*".off"
    end
    
    io = open(file)
    m = mesh(Float64)

    ctrv = 0
    ctrf = 0
    ctre = 0
    nbv = 0
    nbf = 0
    nbe = 0
    for txt in eachline(io)

        l = split(txt);
        if length(l)==0
            #  @info("...", length(l))
            continue
        end
        if l[1] == "OFF"
            continue
        end
        if nbv==0
            nbv=parse(Int64, split(split(l[1],"//")[1],"/")[1]  );
            nbf=parse(Int64, split(split(l[2],"//")[1],"/")[1]  );
            nbe=parse(Int64, split(split(l[3],"//")[1],"/")[1]  );
            continue
        end
        if ctrv<nbv
            ctrv+=1;
            pt = Float64[]
            s = 0
            for i in 1:length(l)
                if length(l[i])>0 && !startswith(l[i]," ") && s<3
                    push!(pt,parse(Float64,l[i]))
                    s+=1
                end
            end
            push_vertex!(m,pt)
        elseif ctrf<nbf
            f = Int64[]
            #@info("face $ctrf $l")
            for i in 2:length(l)
                if length(l[i])>0 && !startswith(l[i]," ")
                    push!(f, 1+parse(Int64, split(split(l[i],"//")[1],"/")[1] ))
                end
            end
            ctrf+=1
            push_face!(m,f)
        else
            #@info("edge $l")
            if ctre<nbe
                e = parse.(Int64, l).+1
                ctre+=1
                push_edge!(m,e)
            end
        end
    end
    close(io)
    return m
end

#----------------------------------------------------------------------
export offdata
"""
Read the off data in the 'file' of the data repository.
```
m = offdata("cube.off")
```

"""
function offdata(file::String)
    m = offread(joinpath(SAT[:pkgdir],"data/off",file))
end


export offprint
"""
Print the mesh 'msh' in a 'file' in OFF format.
```
m = offprint(msh, "file.off")
```
The file name is optional. The default file is "tmp.off". 

"""
function offprint(msh::HMesh, file="tmp.off")
    io = open(file,"w")
    print(io,"OFF\n")
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

function offprint(msh::Mesh, file="tmp.off")
    io = open(file,"w")
    print(io,"OFF\n")
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
