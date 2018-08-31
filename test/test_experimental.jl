@testset "Collect" begin
    c = Collect(5)
    iter = randn(10)
    @test c(iter) == iter[1:5]
    c = Collect(20)
    @test c(iter) == iter
end
