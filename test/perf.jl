module Perf
using PhaseSpaceIO
using PhaseSpaceIO.Testing

function compute_sum_E_mmap(path)
    ps = PhspVector(path)
    sum(p->p.E, ps)
end
function compute_sum_E_iter(path)
    phsp_iterator(path) do iter
        sum(p->p.E, iter)
    end
end
ncase = 10^7
for (P, ext) in [
        (EGSParticle{Float32}, ".egsphsp"),
        (IAEAParticle{0,0}, ".IAEAphsp"),
        ]
    @show P
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
end
