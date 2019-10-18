using Mmap: Mmap
export EGSVector

"""
EGSVector

A read only memory mapped Phase Space vector.
The user is responsible for closing the `io`.
"""
struct EGSVector{P} <: AbstractVector{P}
    io::IOStream
    array::Vector{P}
    # owns_io::Bool
    function EGSVector(io::IO)
        h = consume_egs_header(io)
        P = ptype(h)
        offset = sizeof(P)
        dims = (Int64(h.particlecount),)
        seekstart(io)
        array = Mmap.mmap(io, Vector{P}, dims, offset)
        new{P}(io, array)
    end
end

function EGSVector(path::AbstractString)
    io = open(path)
    EGSVector(io)
end

for (f, args) in [
        [:(Base.size), ()],
        [:(Base.getindex), (:(inds...),)],
    ]
    @eval $f(o::EGSVector, $(args...)) = $f(o.array, $(args...))
end
