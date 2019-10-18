module TestMmap
using Test
using PhaseSpaceIO
using PhaseSpaceIO.Testing
const P = PhaseSpaceIO
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

            ps2 = PhspVector(path)
            p1 = first(ps)
            p2 = first(ps2)
            @test p1.w == p2.w
            @test length(ps2) == length(ps)
            @test first(ps) == first(ps2)
            @test last(ps) == last(ps2)
            @test ps2 == ps
        end
    end
end

@testset "validate_record_constants" begin
    R = typeof((E = Float32(1), weight = Float32(2)))
    @test P.validate_record_constants(Bool, R)
    R = typeof((E = Float64(1), weight = Float32(2)))
    @test !P.validate_record_constants(Bool, R)
    R = typeof((E = Float32(1), weight = Float32(2), w=Float32(1)))
    @test !P.validate_record_constants(Bool, R)
end

h = StaticIAEAHeader((E=Float32(1), weight=Float32(2)),0,0)()
@test sizeof(h) === 0

end#module
