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
        ps = P[arbitrary(P) for _ in 1:n]
        path = tempname() * ".egsphsp1"
        egs_writer(path,P) do w
            for p in ps
                write(w, p)
            end
        end
        @test ispath(path)
        ps_reload = egs_iterator(collect, path)
        @test all(ps_reload .≈ ps)
        @test eltype(ps) == eltype(ps_reload)
        rm(path)
    end
end

@testset "simple phase spaces" begin
    
    path = assetpath("photon_electron_positron.egsphsp")
    h_truth = PhaseSpaceIO.EGSHeader{EGSParticle{Float32}}(3, 1, 1.0f0, 0.83312154f0, 1.0f0)
    ps_truth = [
        EGSParticle(typ=photon, E=1.0, weight=5.2134085, x=2.0, y=-3.0, u=0.99884456, v=-0.03811472, w=0.029271236, new_history=false, zlast=0.23947382f0, latch=0),
        EGSParticle(typ=electron, E=0.8331216, weight=9.296892, x=-0.41874805, y=-0.04104328, u=0.18903294, v=-0.29983893, w=-0.93507385, new_history=true, zlast=1.3316472f0, latch=1073741824),
        EGSParticle(typ=positron, E=0.6077692, weight=0.8328271, x=0.922653, y=0.9263571, u=0.22435355, v=-0.41052637, w=-0.8838176, new_history=false, zlast=1.0724568f0, latch=536870912),
    ]
    h_loaded, ps_loaded = phsp_iterator(path) do iter
        iter.header, collect(iter)
    end
    @test ps_truth == ps_loaded
    @test h_truth == h_loaded
end

@testset "finalizer" begin
    function write_sloppy(path, ps)
        P = eltype(ps)
        w = egs_writer(path, P)
        for p in ps
            write(w, p)
        end
    end
    path = tempname() * ".egsphsp"
    ps = [arbitrary(EGSParticle{Nothing})]
    write_sloppy(path, ps)
    GC.gc()
    ps2 = phsp_iterator(collect, path)
    @test length(ps) == length(ps2) == 1
    @test first(ps) ≈ first(ps2)
    rm(path)
end

end #module
