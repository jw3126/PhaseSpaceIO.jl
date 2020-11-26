module TestOptional
using StaticArrays
using Rotations
using CoordinateTransformations
using Test
using PhaseSpaceIO
using PhaseSpaceIO.Testing
using Accessors
using PhaseSpaceIO: position
using PhaseSpaceIO
using PhaseSpaceIO: propagate_z, position
using PhaseSpaceIO.Testing
using Accessors
using Test
using LinearAlgebra

@testset "SetZ" begin
    p = arbitrary(EGSParticle{Float32})
    z = randn(Float32)
    p2 = SetZ(z)(p)
    @test p2 isa EGSParticleZ
    @test p2.z === z
    @test p2 === @set p.z = z
end

@testset "propagate_z" begin
    for p in [
        arbitrary(EGSParticleZ{Float32}),
        arbitrary(EGSParticleZ{Nothing}),
        arbitrary(IAEAParticle{1,1}),
        arbitrary(IAEAParticle{0,1}),
        arbitrary(IAEAParticle{0,0}),
        (
         position=@SVector(randn(3)),
         direction = normalize(@SVector(randn(3))),
        ),
        (
         position=@SVector(randn(3)),
         direction = normalize(@SVector(randn(3))),
         E = rand(),
         weight = rand(),
        )
        ]

        p = @set direction(p) = @SVector[0,0,1]
        z_to = randn()
        p2 = @inferred propagate_z(p, z_to)
        p2_expected =@set position(p)[3] = position(p2)[3]
        @test position(p2)[3] ≈ z_to
        @test p2 === p2_expected
    end

    dir = normalize([0,1,1])
    pos = [0,0,-100]
    pos_new = [0,100,0]
    p = arbitrary(IAEAParticle{0,0})
    p = @set position(p) = pos
    p = @set direction(p) = dir
    p2 = propagate_z(p, 0.0)
    @test p2 == (@set position(p) = pos_new)

    dir = normalize([0,1,1])
    pos = randn(Float32, 3)
    z_to = pos[3] + 100
    p = arbitrary(EGSParticleZ{Nothing})
    p = @set position(p) = pos
    p = @set direction(p) = dir
    p2 = propagate_z(p, z_to)
    x,y,z=pos
    pos_new = [x, y+100, z+100]
    @test position(p2) == pos_new

    p = arbitrary(EGSParticle{Nothing})
    @test_throws ArgumentError propagate_z(p, 1f0)
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
