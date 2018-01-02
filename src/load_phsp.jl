@generated function readtuple(io::IO, ::Type{T}) where {T <: Tuple}
    args = [:(read(io, $Ti)) for Ti ∈ T.parameters]
    Expr(:call, :tuple, args...)
end

function compressed_particle_sizeof(h::Header{Nf, Ni}) where {Nf, Ni}
    fieldsize(field) = isnull(field) ? 4 : 0
    1 + # typ
    4 + # energy
    fieldsize(h.x) + 
    fieldsize(h.y) + 
    fieldsize(h.z) + 
    fieldsize(h.u) + 
    fieldsize(h.v) + 
    fieldsize(h.weight) + 
    4 * Nf +
    4 * Ni
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
    shift!(buf)
end
function readbuf!(T::Type{Int8}, buf::ByteBuffer)
    reinterpret(T, readbuf!(UInt8, buf))
end

function readbuf!(::Type{UInt32}, buf::ByteBuffer)
    b4 = UInt32(shift!(buf)) << 0
    b3 = UInt32(shift!(buf)) << 8
    b2 = UInt32(shift!(buf)) << 16
    b1 = UInt32(shift!(buf)) << 24
    b1 + b2 + b3 + b4
end

for item ∈ [:x, :y, :z, :u, :v, :weight]
    fread = Symbol("readbuf_", item, "!")
    fwrite = Symbol("write_", item)
    @eval function $fread(buf::ByteBuffer, h::Header)
        if isnull(h.$item)
            readbuf!(Float32, buf)
        else
            get(h.$item)
        end
    end
    @eval function $fwrite(io::IO, p::Particle, h::Header)
        val = isnull(h.$item) ? p.$item : get(h.$item)
        write(io, val)
    end
end

function read_particle(io::IO, h::Header)
    bufsize = compressed_particle_sizeof(h)
    buf = Vector{UInt8}(bufsize)
    read_particle_explicit_buf(io, h, buf, bufsize)
end

function read_particle_explicit_buf(io::IO, h::Header, buf::ByteBuffer, bufsize)
    readbytes!(io, buf, bufsize)
    @assert length(buf) == bufsize
    p = readbuf_particle!(buf, h)
    @assert length(buf) == 0
    p
end


@noinline function readbuf_particle!(buf::ByteBuffer, h::Header{Nf, Ni}) where {Nf, Ni}

    P = ptype(h)
    typ8 = readbuf!(Int8, buf)
    typ = ParticleType(abs(typ8))
    E = readbuf!(Float32, buf)
    new_history = E < 0
    E = abs(E)
    x = readbuf_x!(buf, h)
    y = readbuf_y!(buf, h)
    z = readbuf_z!(buf, h)
    u = readbuf_u!(buf, h)
    v = readbuf_v!(buf, h)
    weight = readbuf_weight!(buf, h)
    
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

@noinline function write_particle(io::IO, p::Particle{Nf, Ni}, h::Header{Nf, Ni}) where {Nf, Ni}
    typ8 = Int8(p.particle_type)
    sign_typ8 = Int8(-1)^(p.w < 0)
    typ8 = sign_typ8 * typ8
    sign_E = Float32(-1)^(p.new_history)
    E = sign_E * p.E
    ret = 0
    ret += write(io, typ8, E)
    ret += write_x(io, p, h)
    ret += write_y(io, p, h)
    ret += write_z(io, p, h)
    ret += write_u(io, p, h)
    ret += write_v(io, p, h)
    ret += write_weight(io, p, h)
    ret += write(io, p.extra_floats...)
    ret += write(io, p.extra_ints...)
    ret
end

ptype(h::Type{Header{Nf, Ni}}) where {Nf, Ni} = Particle{Nf, Ni}
ptype(::Type) = error("$T has no ptype")
ptype(h) = ptype(typeof(h))

@noinline function readphsp(io::IO, h::Header)
    P = ptype(h)
    ret = P[]
    buf = Vector{UInt8}()
    bufsize = compressed_particle_sizeof(h)
    while !eof(io)
        p = read_particle_explicit_buf(io, h, buf, bufsize)
        push!(ret, p)
    end
    ret
end
