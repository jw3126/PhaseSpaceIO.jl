abstract type AbstractPhspIterator end
abstract type AbstractParticle end
abstract type AbstractIAEAParticle <: AbstractParticle end

abstract type Format end
struct FormatEGS <: Format end
struct FormatIAEA <: Format end

Format(p::AbstractIAEAParticle) = FormatIAEA()
Base.length(iter::AbstractPhspIterator) = iter.length

function Base.iterate(iter::AbstractPhspIterator)
    seekstart(iter.io)
    _iterate(iter)
end
function Base.iterate(iter::AbstractPhspIterator, state)
    _iterate(iter)
end

@inline function _iterate(iter::AbstractPhspIterator)
    io = iter.io
    h = iter.header
    P = ptype(h)
    if eof(iter.io)
        nothing
    else
        p = read_particle(io, h)
        dummy_state = nothing
        p, dummy_state
    end
end

function Base.IteratorSize(iter::AbstractPhspIterator)
    Base.HasLength()
end
function Base.IteratorSize(iter::Base.Iterators.Take{<:AbstractPhspIterator}) 
    Base.IteratorSize(iter.xs)
end
function Base.close(iter::AbstractPhspIterator)
    close(iter.io)
end

"""
    ptype(h)

Return type of particles from header.
"""
function ptype end
ptype(T::Type) = error("$T has no ptype")
ptype(h) = ptype(typeof(h))
