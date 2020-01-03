module TestOptional
using StaticArrays
using Rotations
using CoordinateTransformations
using Test
using PhaseSpaceIO
using PhaseSpaceIO.Testing
using Setfield
using PhaseSpaceIO: position
using PhaseSpaceIO
using PhaseSpaceIO: propagate_z, position
using PhaseSpaceIO.Testing
using Setfield
using Test
using LinearAlgebra

@testset "propagate_z" begin
    for p in [
        # (position=randn(3), direction=randn(3)),
        arbitrary(EGSParticle{Float32}),
        arbitrary(EGSParticle{Nothing}),
        arbitrary(IAEAParticle{1,1}),
        arbitrary(IAEAParticle{0,1}),
        arbitrary(IAEAParticle{0,0}),
        ]

        p = @set direction(p) = [0,0,1f0]
        z_to = randn()
        if p isa IAEAParticle
            z_from = nothing
        else
            z_from = randn()
        end
        p2 = @inferred propagate_z(p, z_from, z_to)
        @test direction(p2) == direction(p)
        @test position(p2)[1] == position(p)[1]
        @test position(p2)[2] == position(p)[2]
        @test get(position(p2), 3, z_to) ≈ z_to

        @test propertynames(p2) == propertynames(p)
        @test typeof(p2) == typeof(p)
    end

    dir = normalize([0,1,1])
    pos = [0,0,-100]
    pos_new = [0,100,0]
    p = arbitrary(IAEAParticle{0,0})
    @set! position(p) = pos
    @set! direction(p) = dir
    p2 = propagate_z(p, nothing, 0.0)
    @test p2 == (@set position(p) = pos_new)

    dir = normalize([0,1,1])
    pos = randn(2)
    z_from = randn()
    z_to = z_from + 100.0
    p = arbitrary(EGSParticle{Nothing})
    @set! position(p) = pos
    @set! direction(p) = dir
    p2 = propagate_z(p, z_from, z_to)
    @test p2 == (@set position(p) = pos + [0, 100])
end

@testset "position, direction" begin
    dir = StaticArrays.normalize(@SVector(randn(3)))
    pos_iaea = @SVector(randn(3))
    pos_egs = @SVector(randn(2))
    for (p, pos, dir) in [
                          (arbitrary(EGSParticle{Float32}), pos_egs, dir),
                          (arbitrary(IAEAParticle{2,3}), pos_iaea, dir),
           ]
        @inferred position(p)
        @inferred direction(p)
        q = @set position(p) = pos
        @test typeof(q) == typeof(p)
        @test q.E === p.E
        @test position(q) ≈ pos
        q = @set direction(p) = dir
        @test typeof(q) == typeof(p)
        @test q.E === p.E

        @test direction(q) ≈ dir
        @test dir ≈ [q.u, q.v, q.w]
    end

    p = arbitrary(EGSParticle{Nothing})
    @test position(p)   === @SVector[p.x, p.y]
    @test position(p,3) === @SVector[p.x, p.y, 3]
    p = arbitrary(EGSParticleZ{Float32})
    @test position(p)   === @SVector[p.x, p.y, p.z]
    p = arbitrary(IAEAParticle{1,2})
    @test position(p)   === @SVector[p.x, p.y, p.z]
end

@testset "coordinate transformations" begin
    p = arbitrary(IAEAParticle{1,2})

    t = Translation(randn(3))
    @test position(t(p)) ≈ t(position(p))
    @test direction(p) ≈ direction(t(p))

    l = LinearMap(rand(AngleAxis))
    @test position(l(p)) ≈ l(position(p))
    @test l(direction(p)) ≈ direction(l(p))

    tl = t ∘ l
    @test position(tl(p)) ≈ position(t(l(p)))
    @test direction(tl(p)) ≈ direction(l(p))
end

end#module
