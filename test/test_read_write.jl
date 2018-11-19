module TestReadWrite
using PhaseSpaceIO
using Test
using Setfield
using PhaseSpaceIO.Testing

using PhaseSpaceIO: ptype, read_particle, write_particle

@testset "read write single particle" begin
    h = RecordContents{0,1}()
    P = ptype(h)
    @test P == IAEAParticle{0,1}
    p_ref = P(photon, 
        1.0f0, 2.0f0, 
        3.0f0, 4.0f0, 5.0f0, 
        0.53259337f0, 0.3302265f0, -0.7792912f0, 
        true, (), (13,))
    
    path = assetpath("some_file.IAEAphsp")
    ps = iaea_iterator(collect, path)
    @test length(ps) == 1
    @test first(ps) == p_ref
    
    io = IOBuffer()
    write_particle(io, p_ref, h)
    seekstart(io)
    p = @inferred read_particle(io, h)
    @test p === p_ref
    @test eof(io)
end


@testset "test IAEAPhspIterator" begin
    path = assetpath("some_file.IAEAphsp")
    phsp = iaea_iterator(path)
    @test length(phsp) == 1
    @test eltype(phsp) === IAEAParticle{0,1}
    @test collect(phsp) == collect(phsp)
    @test length(collect(phsp)) == 1
    close(phsp)
end

function test_header_contents(path)
    s = read(path, String)
    for key in [
        :IAEA_INDEX,
        :TITLE,
        :FILE_TYPE,
        :CHECKSUM,
        :RECORD_LENGTH,
        :BYTE_ORDER,
        :ORIG_HISTORIES,
        :PARTICLES,
        :TRANSPORT_PARAMETERS,
        :MACHINE_TYPE,
        :MONTE_CARLO_CODE_VERSION,
        :GLOBAL_PHOTON_ENERGY_CUTOFF,
        :GLOBAL_PARTICLE_ENERGY_CUTOFF,
        :COORDINATE_SYSTEM_DESCRIPTION,
        :BEAM_NAME,
        :FIELD_SIZE,
        :NOMINAL_SSD,
        :MC_INPUT_FILENAME,
        :VARIANCE_REDUCTION_TECHNIQUES,
        :INITIAL_SOURCE_DESCRIPTION,
        :PUBLISHED_REFERENCE,
        :AUTHORS,
        :INSTITUTION,
        :LINK_VALIDATION,
        :ADDITIONAL_NOTES,]
        @test occursin(string(key), s)
    end
end

@testset "test iaea_iterator iaea_writer" begin
    for _ in 1:100
        f = rand(1:3)
        i = rand(1:3)
        n = rand(1:1000)
        ps = [arbitrary(IAEAParticle{f,i}) for _ in 1:n]
        r = RecordContents{f,i}()
        dir = tempname()
        mkpath(dir)
        path = IAEAPath(joinpath(dir, "hello"))
        iaea_writer(path,r) do w
            for p in ps
                write(w, p)
            end
        end
        @test ispath(path.header)
        @test ispath(path.phsp)
        test_header_contents(path.header)

        ps_reload = iaea_iterator(collect, path)
        @test all(ps_reload .≈ ps)
        rm(path)

        @test !ispath(path.header)
        @test !ispath(path.phsp)
    end
end

end
