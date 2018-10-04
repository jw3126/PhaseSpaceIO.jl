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
    weight_function=p->p.weight,
    kw...)
    getters = Base.front(getters_particles)
    particles = Base.last(getters_particles)
    data = map_many_functions(getters, particles)
    weight = Weights(map(weight_function, particles))
    # if use_particle_weights
    #     weight = Weights(map(p->p.weight, particles))
    # else
    #     weight = Weights(fill(Float32(1), length(particles)))
    # end
    if edges == nothing
        fit(Histogram, data, weight; closed=closed, kw...)
    else
        fit(Histogram, data, weight, edges; closed=closed, kw...)
    end
end

function Base.filter(f, iter::PhaseSpaceIterator; maxlength=10^7)
    if maxlength == nothing
        maxlength = -1
    end
    ret = eltype(iter)[]
    count = 0
    for p in iter
        if count == maxlength
            @warn("maxlength=$maxlength reached. Use `maxlength`=nothing to prevent this.")
            break
        end
        if f(p)
            count += 1
            push!(ret, p)
        else

        end
    end
    ret
end
