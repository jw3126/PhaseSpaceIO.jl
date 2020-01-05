export PhspVector
export MultiPhspVector
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

struct MultiPhspVector{P,H} <: AbstractVector{P}
    header::H # egs header can only contain typemax(Int32) particles
    phsps::Vector{PhspVector{P,H}}
    offsets::Vector{Int64}
end

function MultiPhspVector(phsps)
    @argcheck length(unique(typeof, phsps)) == 1
    header = reduce_headers(map(phsp -> phsp.header, phsps))
    offsets = cumsum(map(length, phsps))
    MultiPhspVector(header, phsps, offsets)
end

function MultiPhspVector(paths::AbstractVector{<: AbstractString})
    phsps = map(PhspVector, paths)
    MultiPhspVector(phsps)
end

function reduce_headers(headers::AbstractVector{<: EGSHeader})
    H = eltype(headers)
    @argcheck typeof(first(headers)) == eltype(headers)
    particlecount = sum(h -> h.particlecount, headers)
    photoncount = sum(h->h.photoncount, headers)
    max_E_kin = maximum(h-> h.max_E_kin, headers)
    min_E_kin_electrons = minimum(h->h.min_E_kin_electrons, headers)
    originalcount = sum(h->h.originalcount, headers)
    H(particlecount, photoncount, max_E_kin, min_E_kin_electrons, originalcount)
end

function reduce_headers(headers::AbstractVector{<:IAEAHeader})
    H = unique(typeof, headers)
    record_contents = only(unique(h -> h.record_contents, headers))
    attributes = OrderedDict{Symbol, String}()
    orig_hist = 0
    for h in headers
        n = get(h.attributes, :ORIG_HISTORIES, nothing)
        if n == nothing
            @goto after_orig_histories
        else
            orig_hist += parse(Int64, n)
        end
    end
    attributes[:ORIG_HISTORIES] = string(orig_hist)
    @label after_orig_histories
    @show H
    ret = H(record_contents, attributes)
    @show typeof(ret)
    ret
end

Base.size(o::MultiPhspVector) = (last(o.offsets),)
function Base.getindex(o::MultiPhspVector, i::Integer)
    iphsp = searchsortedfirst(o.offsets, i)
    phsp = o.phsps[iphsp]
    offset = get(o.offsets, iphsp-1, 0)
    ilocal = i - offset
    phsp[ilocal]
end
