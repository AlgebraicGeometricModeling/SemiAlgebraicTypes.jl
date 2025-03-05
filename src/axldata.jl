export axldata
"""
Read the axl data in the 'file' of the data repository.
```
m = axldata("y1m1.axl")
```

"""
function axldata(file::String)
    
    m = axlread(joinpath(SAT[:pkgdir],"data/axl",file))
end
