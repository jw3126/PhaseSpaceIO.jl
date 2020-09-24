module Perf
using PhaseSpaceIO
using PhaseSpaceIO.Testing
using Test
using PhaseSpaceIO.Getters

@testset "Getters don't allocate" begin
    PS = [
        EGSParticle{Nothing},
        EGSParticle{Float32},
        IAEAParticle{0,0},
        IAEAParticle{2,1},
    ]
    @testset "P = $P" for P in PS
        ps = [arbitrary(P) for _ in 1:10^3]
        getters = [E,x,y,z, u,v,w]
        @testset "f = $f" for f in getters
             T = typeof(f(first(ps)))
             out = similar(ps, T)
             map!(f, out, ps)
             bytes = @allocated map!(f, out, ps)
             @test bytes == 0
        end
    end
end

@noinline function sum_E(ps)
    sum(p->p.E, ps)
end

function compute_sum_E_mmap(path)
    ps = PhspVector(path)
    sum_E(ps)
end
function compute_sum_E_iter(path)
    phsp_iterator(sum_E, path)
end

ncase = 10^6
for (P, ext) in [
        (EGSParticle{Float32}, ".egsphsp"),
        (IAEAParticle{0,0}, ".IAEAphsp"),
        ]
    println("*"^80)
    println("Benchmarking $P")
    ps = [arbitrary(P) for _ in 1:ncase]
    path = tempname() * ext
    path2 = tempname() * ext
    println("write $ncase particle")
    phsp_write(path2, ps[1:10])
    @time phsp_write(path, ps)

    println("compute_sum_E_mmap")
    compute_sum_E_mmap(path2)
    @time compute_sum_E_mmap(path)

    println("compute_sum_E_iter")
    compute_sum_E_iter(path2)
    @time compute_sum_E_iter(path)
end
println("*"^80)

end
