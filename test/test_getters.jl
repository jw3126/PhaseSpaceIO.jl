module TestGetters
using Test
using PhaseSpaceIO
using PhaseSpaceIO.Testing
using PhaseSpaceIO.Getters
using Setfield
using StaticArrays

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

    dir = StaticArrays.normalize(@SVector(randn(3)))
    pos_iaea = @SVector(randn(3))
    pos_egs = @SVector(randn(2))
    for (p, pos, dir) in [
                          (arbitrary(EGSParticle{Float32}), pos_egs, dir),
                          (arbitrary(IAEAParticle{2,3}), pos_iaea, dir),
           ]
        q = set_position(p, pos)
        @test typeof(q) == typeof(p)
        @test q.E === p.E
        @test position(q) ≈ pos
        
        q = set_direction(p, dir)
        @test typeof(q) == typeof(p)
        @test q.E === p.E

        @test direction(q) ≈ dir
        @test dir ≈ [q.u, q.v, q.w]
    end

    p = arbitrary(EGSParticle{Nothing})
    @test position(p) == [p.x, p.y]
    @test position(p,z=3) == [p.x, p.y, 3]

    p = arbitrary(IAEAParticle{1,2})
    @test position(p) == [p.x, p.y, p.z]
end

end
