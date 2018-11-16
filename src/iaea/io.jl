function ptype_disksize_nodefaults(h::RecordContents{Nf, Ni}) where {Nf, Ni}
    1 + # typ
    4 + # energy
    12 + # x,y,z
    8 + # u,v (w is not stored)
    4 + # weight
    4 * Nf +
    4 * Ni
end

function ptype_disksize(h::RecordContents{Nf, Ni}) where {Nf, Ni}
    size_reduction_due_to_defaults = sizeof(h.data)
    ptype_disksize_nodefaults(h) - size_reduction_due_to_defaults
end

@generated function readbuf_default!(buf::ByteBuffer,
                             ::Val{field},
                             h::RecordContents{Nf,Ni,NT}) where {field,Nf,Ni,NT}
    if field in fieldnames(NT)
        :(h.data.$field)
    else
        :(readbuf!(Float32, buf))
    end
end

@generated function write_default(io::IO,
                             ::Val{field},
                             p::IAEAParticle,
                             h::RecordContents{Nf,Ni,NT}) where {field,Nf,Ni,NT}
    if field in fieldnames(NT)
        quote
            @assert p.$field == h.data.$field
            0
        end
    else
        :(write(io, p.$field))
    end
end
@noinline function readbuf_particle!(buf::ByteBuffer, h::RecordContents{Nf, Ni}) where {Nf, Ni}

    P = ptype(h)
    typ8 = readbuf!(Int8, buf)
    typ = ParticleType(abs(typ8))
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
    u,v,w = compute_u_v_w(u,v,sign_w)
    
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
                                  p::IAEAParticle{Nf, Ni},
                                  h::RecordContents{Nf, Ni}) where {Nf, Ni}
    typ8 = Int8(p.typ)
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

ptype(h::Type{RecordContents{Nf, Ni, NT}}) where {Nf, Ni, NT} = IAEAParticle{Nf, Ni}
