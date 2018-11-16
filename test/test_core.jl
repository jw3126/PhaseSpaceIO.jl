module TestCore
using PhaseSpaceIO
using PhaseSpaceIO.Testing: arbitrary
using Test
using Base.Meta
@testset "show" begin
    p_iaea = Particle(typ=photon,E=1.23,x=1,y=2,z=3,
                 u=0,v=0,w=1)
    p_egs = EGSParticle(typ=electron, E=1.23, x=1, y=2,
                        u=0,v=0,w=1)
    for p in [p_egs, p_iaea,]
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
end
