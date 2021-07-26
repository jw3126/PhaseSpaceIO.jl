module TestGetters
using Test
using PhaseSpaceIO
using PhaseSpaceIO.Testing
using PhaseSpaceIO.Getters
using Accessors
using ConstructionBase

@testset "test getters" begin
    p = arbitrary(IAEAParticle{0,1})
    p = @set p.x = 100
    @test x(p) ≈ 100
    p = @set p.E = 10
    p = @set p.weight = 1
    @test energy(p) == 10
    p = @set p.weight = 0.1
    @test energy(p) ≈ 1


    p = arbitrary(EGSParticle{Float32})
    p = @set p.x = 1000f0
    @test x(p) ≈ 1000
    p = @set p.zlast = nothing
    @test p.zlast == nothing
    p = @set p.zlast = 1f0
    @test p.zlast == 1f0
    l = p.latch
    @test getproperties(l) isa NamedTuple
    @test propertynames(l) == propertynames(getproperties(l))
    @test l == setproperties(l, getproperties(l))

    for p in [arbitrary(IAEAParticle{0,1}), arbitrary(EGSParticle{Float32})]
        nt = getproperties(p)
        @test getproperties(p) isa NamedTuple
        @test propertynames(nt) == propertynames(p)
        @test setproperties(p, nt) == p
    end
end

end
