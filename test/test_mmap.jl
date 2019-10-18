module TestMmap
using Test
using PhaseSpaceIO
using PhaseSpaceIO.Testing
using PhaseSpaceIO: Format, FormatEGS, FormatIAEA

@testset "mmap $P" for P in [EGSParticle{Nothing},
                          EGSParticle{Float32},
                          IAEAParticle{0,0},
                          IAEAParticle{1,0},
                          IAEAParticle{0,1},
                          IAEAParticle{rand(0:3), rand(0:3)},
                         ]

    mktempdir() do dir
        for len in [1,2,3,4,10,100,rand(1000:2000)]
            ps = [arbitrary(P) for _ in 1:len]
            if Format(first(ps)) isa FormatEGS
                path = joinpath(dir, "phsp.egsphsp")
            else
                path = joinpath(dir, "phsp.IAEAheader")
            end
            phsp_write(path, ps)

            ps1 = phsp_iterator(collect, path)
            ps2 = PhspVector(path)
            @test all(ps1 .≈ ps)
            @test all(ps2 .≈ ps)

            p1 = first(ps)
            p2 = first(ps2)
            @test p1.w == p2.w
            @test length(ps2) == length(ps)
            @test first(ps) == first(ps2)
            @test last(ps) == last(ps2)
            @test ps1 == ps2
            # for (p1, p2) in zip(ps1, ps2)
            #     @test p1.u == p2.u
            #     @test p1.v == p2.v
            #     @test p1.w == p2.w
            #     @test p1 == p2
            # end
        end
    end
end

end#module
