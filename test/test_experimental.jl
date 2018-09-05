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

end
