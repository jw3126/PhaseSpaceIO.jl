#### EGSHeader, EGSPhspIterator
struct EGSHeader{P<:EGSParticle}
    particlecount::Int32
    photoncount::Int32
    max_E_kin::Float32
    min_E_kin_electrons::Float32
    originalcount::Float32
end

function read_ZLAST(io::IO)
    mode = prod([read(io, Char) for _ in 1:5])
    if mode == "MODE0"
        Nothing
    elseif mode == "MODE2"
        Float32
    else
        error("Unknown mode $mode")
    end
end

function consume_egs_header(io::IO)
    ZLAST = read_ZLAST(io)
    P = EGSParticle{ZLAST}
    nphsp      = read(io, Int32)
    nphotphsp  = read(io, Int32)
    ekmaxphsp  = read(io, Float32)
    ekminphsp  = read(io, Float32)
    nincphsp   = read(io, Float32)
    EGSHeader{P}(nphsp, nphotphsp, ekmaxphsp, ekminphsp, nincphsp)
end

ptype(::Type{EGSHeader{P}}) where {P} = P

struct EGSPhspIterator{P <: EGSParticle, I <:IO} <: AbstractPhspIterator
    io::I
    header::EGSHeader{P}
    buffer::Base.RefValue{P}
    length::Int64
end

Base.eltype(::Type{<:EGSPhspIterator{P}}) where {P} = P

function egs_iterator(io::IO)
    h = consume_egs_header(io)
    total_size  = bytelength(io)
    P = ptype(h)
    float_len = (total_size / sizeof(P)) - 1
    len = floor(Int64, float_len)
    if float_len != len
        @warn "File size indicates $(float_len) particles, which is not an integer. Assuming $(len) particles instead."
    end
    if len != h.particlecount
        @warn "Particle count according to the header is $(h.particlecount), while there are actually $(float_len) particles stored in the file."
    end
    buffer = Base.RefValue{P}()
    EGSPhspIterator(io, h, buffer, len)
end

function Base.iterate(iter::EGSPhspIterator, nread=0)
    # skip header
    if nread == 0
        pos = sizeof(ptype(iter.header))
        seek(iter.io, pos)
    end
    if nread == length(iter)
        return nothing
    else
        p = read!(iter.io, iter.buffer)[]
        nread += 1
        p, nread
    end
end

zlast_type(P::Type{EGSParticle{ZLAST}}) where {ZLAST} = ZLAST
zlast_type(p::EGSParticle{ZLAST}) where {ZLAST} = ZLAST
zlast_type(o) = zlast_type(ptype(o))

function write_header(io::IO, h::EGSHeader)
    ZLAST = zlast_type(h)
    mode = if ZLAST == Nothing
        "MODE0"
    else
        @assert ZLAST == Float32
        "MODE2"
    end

    ret = 0
    ret += write(io, mode)
    ret += write(io, h.particlecount)
    ret += write(io, h.photoncount)
    ret += write(io, h.max_E_kin)
    ret += write(io, h.min_E_kin_electrons)
    ret += write(io, h.originalcount)
    psize = sizeof(ptype(h))
    while (ret < psize)
        ret += write(io, '\0')
    end
    @assert ret == psize
    ret
end

mutable struct EGSWriter{P <: EGSParticle, I <: IO}
    io::I
    particlecount::Int32
    photoncount::Int32
    max_E_kin::Float32
    min_E_kin_electrons::Float32
    originalcount::Float32
    buffer::Base.RefValue{P}
    function EGSWriter{P}(io::I, particlecount, photoncount,
                       max_E_kin, min_E_kin_electrons,
                       originalcount, buffer) where {P,I}

        w = new{P,I}(io, particlecount, photoncount,
                       max_E_kin, min_E_kin_electrons,
                       originalcount, buffer)
        finalizer(close, w)
        w
    end
end

function Base.write(w::EGSWriter{P}, p::P) where {P <: EGSParticle}
    w.particlecount += 1
    if isphoton(p)
        w.photoncount += 1
    end
    w.max_E_kin = max(w.max_E_kin, p.E)
    if iselectron(p)
        w.min_E_kin_electrons = min(w.min_E_kin_electrons, p.E)
    end
    w.buffer[] = p
    write(w.io, w.buffer)
end

function create_header(w::EGSWriter{P}) where {P}
    h = EGSHeader{P}(
        w.particlecount::Int32,
        w.photoncount::Int32,
        w.max_E_kin::Float32,
        w.min_E_kin_electrons::Float32,
        w.originalcount::Float32,
   )
end


"""
    egs_writer(f, path, P::Type{<:EGSParticle})

Write particles in EGS format to `path`:
```jldoctest
julia> using PhaseSpaceIO

julia> p = EGSParticle(
           E=1.0, weight=5.2134085,
           x=2.0, y=-3.0,
           u=0.99884456, v=-0.03811472, w=0.029271236,
           new_history=false, zlast=0.23947382f0, latch=Latch(charge=0));

julia> path = tempname() * ".egsphsp1";

julia> egs_writer(path, typeof(p)) do w
           write(w, p)
       end
32

julia> phsp_iterator(collect, path)
1-element Array{EGSParticle{Float32},1}:
 EGSParticle(latch=Latch(multicross=false, charge=0, creation=0, visited=@BitRegions(), brems=fals
e, ), new_history=false, E=1.0f0, x=2.0f0, y=-3.0f0, u=0.99884456f0, v=-0.03811472f0, w=0.02927123
6f0, weight=5.2134085f0, zlast=0.23947382f0, )
```
"""
function egs_writer(f, path, P)
    w = egs_writer(path, P)
    ret = call_fenced(f,w)
    close(w)
    ret
end

function egs_writer(path::AbstractString, P)
    io = open(path, "w")
    egs_writer(io, P)
end

function egs_writer(io::IO, ::Type{P}) where {P <: EGSParticle}
    buffer = Base.RefValue{P}()
    w = EGSWriter{P}(io, Int32(0),Int32(0),Float32(-Inf),Float32(Inf),Float32(1.), buffer)
    h = create_header(w)
    write_header(io, h)
    w
end

function Base.flush(w::EGSWriter)
    if isopen(w.io)
        h = create_header(w)
        pos = Base.position(w.io)
        seekstart(w.io)
        write_header(w.io, h)
        seek(w.io, pos)
    end
    flush(w.io)
end

function Base.close(w::EGSWriter)
    flush(w)
    close(w.io)
end
