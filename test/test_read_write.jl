module TestReadWrite
using PhaseSpaceIO
using Test
using Setfield

using PhaseSpaceIO: ptype, read_particle, write_particle

assetpath(args...) = joinpath(@__DIR__, "assets", args...)

@testset "read write single particle" begin
    h = Header{0,1}()
    P = ptype(h)
    @test P == Particle{0,1}
    p_ref = P(photon, 
        1.0f0, 2.0f0, 
        3.0f0, 4.0f0, 5.0f0, 
        0.53259337f0, 0.3302265f0, -0.7792912f0, 
        true, (), (13,))
    
    path = assetpath("some_file.IAEAphsp")
    ps = open_phsp(collect, path)
    @test length(ps) == 1
    @test first(ps) == p_ref
    
    io = IOBuffer()
    write_particle(io, p_ref, h)
    seekstart(io)
    p = @inferred read_particle(io, h)
    @test p === p_ref
    @test eof(io)
end

end
