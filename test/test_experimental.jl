module TestExperimental
using Setfield
using PhaseSpaceIO
using Test

@testset "Collect" begin
    c = Collect(5)
    iter = randn(10)
    @test c(iter) == iter[1:5]
    c = Collect(20)
    @test c(iter) == iter
end

@testset "Setfield" begin
    p = Particle(1,2,3,4,5,6,0,0,1,true,(),())
    q = @set p.x = 10
    @test q.x == 10
    @test p.x == 4
end

@testset "energy" begin
    p = Particle{0,1}(photon, 1.0f0, 2.0f0, 3.0f0, 4.0f0, 5.0f0, 
            0.53259337f0, 0.3302265f0, -0.7792912f0,
            true, (), (13,))
    p = @set p.E = 10
    p = @set p.weight = 1
    @test energy(p) == 10
    p = @set p.weight = 0.1
    @test energy(p) ≈ 1
end

end
