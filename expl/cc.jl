using SemiAlgebraicTypes
using Axl

datadir="../data/"

#m = axlread(joinpath(datadir,"forprojection/cube.axl"))[1]
#m = axlread(joinpath(datadir,"sbd/hexagon.axl"))[1]
m = axlread(joinpath(datadir,"sbd/square1.axl"))[1]

m[:color] = Color(0,0,255)
m[:size] = 0.25

hm = hmesh(m)
hm[:color] = Color(255,0,0)
hm[:size] = 0.25

cc_subdivide!(hm,2)

#cc_subdivide!(hm)

@axlview hm, m

