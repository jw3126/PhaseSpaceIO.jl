module TestReadWrite
using PhaseSpaceIO
using Test
using Setfield
using PhaseSpaceIO.Testing

using PhaseSpaceIO: ptype, read_particle, write_particle

assetpath(args...) = joinpath(@__DIR__, "assets", args...)

@testset "read write single particle" begin
    h = RecordContents{0,1}()
    P = ptype(h)
    @test P == Particle{0,1}
    p_ref = P(photon, 
        1.0f0, 2.0f0, 
        3.0f0, 4.0f0, 5.0f0, 
        0.53259337f0, 0.3302265f0, -0.7792912f0, 
        true, (), (13,))
    
    path = assetpath("some_file.IAEAphsp")
    ps = phsp_iterator(collect, path)
    @test length(ps) == 1
    @test first(ps) == p_ref
    
    io = IOBuffer()
    write_particle(io, p_ref, h)
    seekstart(io)
    p = @inferred read_particle(io, h)
    @test p === p_ref
    @test eof(io)
end


@testset "test PhaseSpaceIterator" begin
    path = assetpath("some_file.IAEAphsp")
    phsp = phsp_iterator(path)
    @test length(phsp) == 1
    @test eltype(phsp) === Particle{0,1}
    @test collect(phsp) == collect(phsp)
    @test length(collect(phsp)) == 1
    close(phsp)
end

@testset "test phsp_iterator phsp_writer" begin
    for _ in 1:5
        f = rand(1:3)
        i = rand(1:3)
        n = rand(1:1000)
        ps = [arbitrary(Particle{f,i}) for _ in 1:n]
        r = RecordContents{f,i}()
        dir = tempname()
        mkpath(dir)
        path = IAEAPath(joinpath(dir, "hello"))
        phsp_writer(path,r) do w
            for p in ps
                write(w, p)
            end
        end
        @test ispath(path.header)
        @test ispath(path.phsp)
        ps_reload = phsp_iterator(collect, path)
        @test all(ps .≈ ps_reload)
        rm(path)

        @test !ispath(path.header)
        @test !ispath(path.phsp)
    end
end

end
