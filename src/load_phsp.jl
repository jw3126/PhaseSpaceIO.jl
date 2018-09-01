@generated function readtuple(io::IO, ::Type{T}) where {T <: Tuple}
    args = [:(read(io, $Ti)) for Ti ∈ T.parameters]
    Expr(:call, :tuple, args...)
end

function comporessed_particle_no_defaults_sizeof(h::Header{Nf, Ni}) where {Nf, Ni}
    1 + # typ
    4 + # energy
    12 + # x,y,z
    8 + # u,v (w is not stored)
    4 + # weight
    4 * Nf +
    4 * Ni
end

function compressed_particle_sizeof(h::Header{Nf, Ni}) where {Nf, Ni}
    size_reduction_due_to_defaults = sizeof(h.default_particle_values)
    comporessed_particle_no_defaults_sizeof(h) - size_reduction_due_to_defaults
end

const ByteBuffer = AbstractVector{UInt8}

@generated function readbuf!( ::Type{T}, buf::ByteBuffer) where {T <: Tuple}
    args = [:(readbuf!($Ti, buf)) for Ti ∈ T.parameters]
    Expr(:call, :tuple, args...)
end

function readbuf!(::Type{T}, buf::ByteBuffer) where {T}
    @argcheck sizeof(T) == sizeof(UInt32)
    reinterpret(T, readbuf!(UInt32, buf))
end

function readbuf!(::Type{UInt8}, buf::ByteBuffer)
    popfirst!(buf)
end
function readbuf!(T::Type{Int8}, buf::ByteBuffer)
    reinterpret(T, readbuf!(UInt8, buf))
end

function readbuf!(::Type{UInt32}, buf::ByteBuffer)
    b4 = UInt32(popfirst!(buf)) << 0
    b3 = UInt32(popfirst!(buf)) << 8
    b2 = UInt32(popfirst!(buf)) << 16
    b1 = UInt32(popfirst!(buf)) << 24
    b1 + b2 + b3 + b4
end

@generated function readbuf_default!(buf::ByteBuffer,
                             ::Val{field},
                             h::Header{Nf,Ni,NT}) where {field,Nf,Ni,NT}
    if field in fieldnames(NT)
        :(h.default_particle_values.$field)
    else
        :(readbuf!(Float32, buf))
    end
end

@generated function write_default(io::IO,
                             ::Val{field},
                             p::Particle,
                             h::Header{Nf,Ni,NT}) where {field,Nf,Ni,NT}
    if field in fieldnames(NT)
        quote
            @assert p.$field == h.default_particle_values.$field
            0
        end
    else
        :(write(io, p.$field))
    end
end

function read_particle(io::IO, h::Header)
    bufsize = compressed_particle_sizeof(h)
    buf = Vector{UInt8}(undef,bufsize)
    read_particle_explicit_buf(io, h, buf)
end

function read_particle_explicit_buf(io::IO, h::Header, buf::ByteBuffer)
    bufsize = compressed_particle_sizeof(h)
    readbytes!(io, buf, bufsize)
    @assert length(buf) == bufsize
    p = readbuf_particle!(buf, h)
    @assert length(buf) == 0
    p
end


@noinline function readbuf_particle!(buf::ByteBuffer, h::Header{Nf, Ni}) where {Nf, Ni}

    P = ptype(h)
    typ8 = readbuf!(Int8, buf)
    typ = convert(ParticleType, abs(typ8))
    E = readbuf!(Float32, buf)
    new_history = E < 0
    E = abs(E)
    x = readbuf_default!(buf, Val(:x), h)
    y = readbuf_default!(buf, Val(:y), h)
    z = readbuf_default!(buf, Val(:z), h)
    u = readbuf_default!(buf, Val(:u), h)
    v = readbuf_default!(buf, Val(:v), h)
    weight = readbuf_default!(buf, Val(:weight), h)
    
    sign_w = Float32(-1)^(typ8 < 0)
    tmp = Float64(u)^2 + Float64(v)^2
    if tmp <= 1
        w = sign_w * Float32(√(1 - tmp))
    else
        w = Float32(0)
        tmp = √(tmp)
        u = Float32(u/tmp)
        v = Float32(v/tmp)
    end
    
    extra_floats = readbuf!(NTuple{Nf, Float32}, buf)
    extra_ints = readbuf!(NTuple{Ni, Int32}, buf)
    P(typ,
        E,weight,
        x,y,z,
        u,v,w,
        new_history,
        extra_floats, extra_ints,
    )
end

@noinline function write_particle(io::IO,
                                  p::Particle{Nf, Ni},
                                  h::Header{Nf, Ni}) where {Nf, Ni}
    typ8 = Int8(p.particle_type)
    sign_typ8 = Int8(-1)^(p.w < 0)
    typ8 = sign_typ8 * typ8
    sign_E = Float32(-1)^(p.new_history)
    E = sign_E * p.E
    ret = 0
    ret += write(io, typ8, E)
    ret += write_default(io, Val(:x), p, h)
    ret += write_default(io, Val(:y), p, h)
    ret += write_default(io, Val(:z), p, h)
    ret += write_default(io, Val(:u), p, h)
    ret += write_default(io, Val(:v), p, h)
    ret += write_default(io, Val(:weight), p, h)
    for f in p.extra_floats
        ret += write(io, f)
    end
    for i in p.extra_ints
        ret += write(io, i)
    end
    ret
end

ptype(h::Type{Header{Nf, Ni, NT}}) where {Nf, Ni, NT} = Particle{Nf, Ni}
ptype(T::Type) = error("$T has no ptype")
ptype(h) = ptype(typeof(h))
