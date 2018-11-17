module TestEGS
using Test
using PhaseSpaceIO
using PhaseSpaceIO.Testing
using PhaseSpaceIO: ptype, EGSHeader, write_header, write_particle, EGSParticle

@testset "read write inverse" begin
    for _ in 1:100
        ZLAST = rand(Bool) ? Nothing : Float32
        P = EGSParticle{ZLAST}
        nparticles = rand(1:100)
        h = arbitrary(EGSHeader{P}, particlecount=nparticles)
        ps = [arbitrary(P) for _ in 1:nparticles]
        io = IOBuffer()
        write_header(io, h)
        for p in ps
            write_particle(io, p, h)
        end
        seekstart(io)
        h2, ps2 = egs_iterator(io) do iter
            iter.header, collect(iter)
        end
        @test all(ps .≈ ps2)
        @test h == h2
        # @test h == h2
    end
end

@testset "test egs_iterator egs_writer" begin
    for _ in 1:100
        ZSLAB = rand(Bool) ? Nothing : Float32
        n = rand(1:1000)
        P = EGSParticle{ZSLAB}
        ps = [arbitrary(P) for _ in 1:n]
        path = tempname() * ".egsphsp1"
        egs_writer(path,P) do w
            for p in ps
                write(w, p)
            end
        end
        @test ispath(path)
        ps_reload = egs_iterator(collect, path)
        @test all(ps_reload .≈ ps)
        rm(path)
    end
end

end #module
