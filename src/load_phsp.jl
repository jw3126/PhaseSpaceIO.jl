@generated function readtuple(io::IO, ::Type{T}) where {T <: Tuple}
    args = [:(read(io, $Ti)) for Ti ∈ T.parameters]
    Expr(:call, :tuple, args...)
end

for item ∈ [:x, :y, :z, :u, :v, :weight]
    fread = Symbol("read_", item)
    fwrite = Symbol("write_", item)
    @eval function $fread(io::IO, h::Header)
        if isnull(h.$item)
            read(io, Float32)
        else
            get(h.$item)
        end
    end
    @eval function $fwrite(io::IO, p::Particle, h::Header)
        val = isnull(h.$item) ? p.$item : get(h.$item)
        write(io, val)
    end
end

@noinline function read_particle(io::IO, h::Header{Nf, Ni}) where {Nf, Ni}
    P = ptype(h)
    typ8 = read(io, Int8)
    typ = ParticleType(abs(typ8))
    E = read(io, Float32)
    new_history = E < 0
    E = abs(E)
    x = read_x(io, h)
    y = read_y(io, h)
    z = read_z(io, h)
    u = read_u(io, h)
    v = read_v(io, h)
    weight = read_weight(io, h)
    
    sign_w = Float32(-1)^(typ8 < 0)
    tmp = Float64(u)^2 + Float64(v)^2
    if tmp <= 1
        w = sign_w * Float32(√(1 - tmp))
    else
        w = Float32(0)
        tmp = √(tmp)
        u = u/tmp
        v = v/tmp
    end
    
    extra_floats = readtuple(io, NTuple{Nf, Float32})
    extra_ints = readtuple(io, NTuple{Ni, Int32})
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
    while !eof(io)
        p = read_particle(io, h)
        push!(ret, p)
    end
    ret
end
