module TestMmap
using Test
using PhaseSpaceIO
using PhaseSpaceIO.Testing

@testset "mmap $P" for P in [EGSParticle{Nothing},
                          EGSParticle{Float32}]

    mktempdir() do dir
        for len in [1,2,3,4,10,100,rand(1000:2000)]
            ps = [arbitrary(P) for _ in 1:len]
            path = joinpath(dir, "phsp.egsphsp")
            phsp_write(path, ps)

            ps2 = EGSVector(path)
            @test length(ps2) == length(ps)
            @test first(ps) === first(ps2)
            @test last(ps) === last(ps2)
            @test eltype(ps2) == eltype(ps)
            @test ps2 == ps

        end
    end
end

end#module
