module TestCore
using PhaseSpaceIO
using Test
using Base.Meta
@testset "show" begin
    p = Particle(typ=photon,E=1.5,x=1,y=2,z=3,
                 u=0,v=0,w=1)
    io = IOBuffer()
    s = sprint(show, p)
    for field in fieldnames(typeof(p))
        sfield = string(field)
        @test occursin(sfield, s)
    end
                 
    ex = Meta.parse(s)
    @test eval(ex) === p
end
end
