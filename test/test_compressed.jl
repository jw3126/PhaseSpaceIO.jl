module TestCompressed
using Accessors: @set
using Test
using PhaseSpaceIO
const PHSP = PhaseSpaceIO
using PhaseSpaceIO.Testing
using PhaseSpaceIO: Format, FormatEGS, FormatIAEA

@testset "==" begin
    for p1 in [arbitrary(IAEAParticle{rand(0:4), rand(0:4)}) for _ in 1:10]
        path = IAEAPath(tempname())
        phsp_write(path, [p1])
        p2 = PhspVector(path)[1]
        
        @test p2 == p1
        @test p1 == p2
        @test @set(p1.z += 0.1) != p2
        @test p2 != @set p1.E += 0.1
        @test p2 != @set p1.x += 0.1
        @test p2 != @set p1.y += 0.1
        @test p2 != @set p1.z += 0.1
        @test p2 != @set p1.u *= -1
        @test p2 != @set p1.v *= -1
        @test p2 != @set p1.w *= -1
        @test p2 != @set p1.weight += 0.1
        @test p2 != @set p1.new_history = !p1.new_history
    end
end

@testset "validate_record_constants" begin
    R = typeof((E = Float32(1), weight = Float32(2)))
    @test PHSP.validate_record_constants(Bool, R)
    R = typeof((E = Float64(1), weight = Float32(2)))
    @test !PHSP.validate_record_constants(Bool, R)
    R = typeof((E = Float32(1), weight = Float32(2), w=Float32(1)))
    @test !PHSP.validate_record_constants(Bool, R)
end

h = StaticIAEAHeader((E=Float32(1), weight=Float32(2)),0,0)()
@test sizeof(h) === 0

end#module
