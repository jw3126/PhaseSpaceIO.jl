export PhspVector
using Mmap: Mmap

"""
PhspVector

A read only memory mapped Phase Space vector.
The user is responsible for closing the `io`.
"""
struct PhspVector{P,H} <: AbstractVector{P}
    io::IOStream
    header::H
    array::Vector{P}
    # owns_io::Bool
    function PhspVector{P,H}(io::IO, header::H) where {P,H}
        offset = if header isa EGSHeader
            sizeof(P)
        else
            0
        end
        dims = (get_nparticles(io, header),)
        seekstart(io)
        array = Mmap.mmap(io, Vector{P}, dims, offset)
        new{P, H}(io, header, array)
    end
end

function get_nparticles_header(h::EGSHeader)
    h.particlecount
end
function get_nparticles_header(h::IAEAHeader)
    parse(Int64, h.attributes[:PARTICLES])
end

function get_nparticles_iosize(P, io::IO)::Float64
    total_size  = bytelength(io)
    ret = (total_size / sizeof(P))
    if P <: EGSParticle
        ret -= 1 # first particle encodes the header
    end
    ret
end

function get_nparticles(io::IO, header)
    P = compressed_ptype(header)
    nheader = get_nparticles_header(header)
    ffilesize = get_nparticles_iosize(P, io)
    nfilesize = floor(Int64, ffilesize)
    if ffilesize != nfilesize
        @warn "File size indicates $(ffilesize) particles, which is not an integer. Assuming $(nfilesize) particles instead."
    end
    if nfilesize != nheader
        @warn "Particle count according to the header is $(nheader), while there are actually $(nfilesize) particles stored in the file."
    end
    nfilesize
end

function PhspVector(io::IO, h::Union{EGSHeader, IAEAHeader})
    P = compressed_ptype(h)
    H = typeof(h)
    PhspVector{P,H}(io, h)
end

function compressed_ptype(h::EGSHeader)
    ptype(h)
end
function compressed_ptype(h::IAEAHeader{Nf, Ni}) where {Nf, Ni}
    ptype(StaticIAEAHeader(h.record_contents, Nf, Ni))
end

function _PhspVector(path::AbstractString, fmt::FormatIAEA)
    _PhspVector(IAEAPath(path), fmt)
end

function _PhspVector(path::IAEAPath, ::FormatIAEA)
    io = open(path.phsp)
    h = load(path.header, IAEAHeader)
    PhspVector(io, h)
end

function _PhspVector(path::AbstractString, ::FormatEGS)
    io = open(path)
    h = consume_egs_header(io)
    seekstart(io)
    PhspVector(io, h)
end

function PhspVector(path::AbstractString)
    fmt = guess_format_from_path(path)
    _PhspVector(path, fmt)
end

function PhspVector(path::IAEAPath)
    _PhspVector(path, FormatIAEA())
end

for (f, args) in [
        [:(Base.size), ()],
        [:(Base.getindex), (:(i::Union{Integer, CartesianIndex}),)],
    ]
    @eval $f(o::PhspVector, $(args...)) = $f(o.array, $(args...))
end

Base.getindex(o::PhspVector, inds...) = view(o, inds...)
