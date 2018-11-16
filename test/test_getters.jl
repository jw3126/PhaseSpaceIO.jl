module TestGetters
using Test
using PhaseSpaceIO
using PhaseSpaceIO.Testing
using PhaseSpaceIO.Getters
using Setfield

@testset "test getters" begin
    p = arbitrary(IAEAParticle{0,1})
    p = @set p.x = 100
    @test x(p) ≈ 100
    p = @set p.E = 10
    p = @set p.weight = 1
    @test energy(p) == 10
    p = @set p.weight = 0.1
    @test energy(p) ≈ 1
end

end
