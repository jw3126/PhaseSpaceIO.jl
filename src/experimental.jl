export Collect
export histmap
export binning
using StatsBase
using ArgCheck

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

function Base.filter(f, iter::IAEAPhspIterator; maxlength=10^7)
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

struct Binning{C,E <: AbstractVector}
    edges::E
    content::Vector{C}
end

function Base.map(f,b::Binning)
    Binning(b.edges, map(f,b.content))
end

function StatsBase.Histogram(b::Binning)
    closed = :right
    isdensity = false
    Histogram(b.edges, b.content, closed, isdensity)
end

function binning_edges_keys_items(edges, keys, items)
    @argcheck length(keys) == length(items)
    T = eltype(items)
    C = Vector{T}
    n = length(edges) - 1
    content = C[C() for _ in 1:n]
    for (key, item) in zip(keys, items)
        index = searchsortedfirst(edges, key) - 1
        index = clamp(index, 1, n)
        push!(content[index], item)
    end
    Binning(edges, content)
end

function get_keys_edges(f, items, nbins::Nothing, edges::Nothing)
    get_keys_edges(f, items, 100, edges)
end

function get_keys_edges(f, items, nbins, edges::Nothing)
    keys = map(f, items)
    kmin,kmax = extrema(keys)
    edges = range(kmin,stop=kmax,length=nbins)
    keys, edges
end

function get_keys_edges(f, items, nbins::Nothing, edges)
    keys = map(f, items)
    keys, edges
end

function get_keys_edges(f, items, nbins, edges)
    @argcheck nbins == length(edges)
    get_keys_edges(f, items, nothing, edges)
end

function binning(f,items, nbins=nothing, edges=nothing)
    keys, edges = get_keys_edges(f, items, nbins, edges)
    binning_edges_keys_items(edges, keys, items)
end
