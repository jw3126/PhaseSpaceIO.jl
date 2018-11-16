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

end #module
