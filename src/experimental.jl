export Collect
export histmap
using StatsBase

struct Collect
    count::Int64
end

function (c::Collect)(iter)
    ret = eltype(iter)[]
    for (i,xi) in enumerate(iter)
        push!(ret, xi)
        i < c.count || break
    end
    return ret
end

function map_many_functions(getters, particles) where {N}
    map(getters) do f
        map(f, particles)
    end
end

function histmap(getters_particles...;
    edges=nothing,
    closed=:right,
    use_particle_weights=true,
    kw...)
    getters = Base.front(getters_particles)
    particles = Base.last(getters_particles)
    data = map_many_functions(getters, particles)
    if use_particle_weights
        weight = Weights(map(p->p.weight, particles))
    else
        weight = Weights(fill(Float32(1), length(particles)))
    end
    if edges == nothing
        fit(Histogram, data, weight; closed=closed, kw...)
    else
        fit(Histogram, data, weight, edges; closed=closed, kw...)
    end
end
