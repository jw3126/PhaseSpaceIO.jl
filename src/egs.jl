export EGSParticle
export Latch

import Setfield
#### Latch
struct Latch
    _data::UInt32
end

Base.UInt32(l::Latch) = getfield(l, :_data)

function Latch(charge::Int)
    Latch(latchpattern(charge))
end

function Latch(;charge)
    Latch(Int(charge))
end

function Base.propertynames(o::Latch)
    (:charge,)
end

function get_charge(latch::Latch)
    l = getfield(latch, :_data)
    latchmask = (1<<30) | (1<<29)
    l &= latchmask
    if l == latchpattern(0)
        0
    elseif l == latchpattern(-1)
        -1
    elseif l == latchpattern(1)
        1
    else
        msg = "Unsupported latch pattern $latch"
        throw(ArgumentError(msg))
    end
end

function latchpattern(charge::Int)::UInt32
    if charge == 0
        UInt32(0)
    elseif charge == -1
        UInt32(1 << 30)
    elseif charge == 1
        UInt32(1 << 29)
    else
        @argcheck charge in (-1, 0, 1)
    end
end

function Base.getproperty(o::Latch, s::Symbol)
    if s == :charge
        get_charge(o)
    else
        @argcheck s in propertynames(o)
    end
end

Base.show(io::IO, o::Latch) = kwshow(io, o)

#### EGSParticle
struct EGSParticle{ZLAST <: Union{Nothing,Float32}}
    _latch::Latch
    _E::Float32 # sign bit new histrory
    _x::Float32
    _y::Float32
    _u::Float32
    _v::Float32
    _weight::Float32 # sign bit sign w
    _zlast::ZLAST
end

# TODO HACKY
Base.isapprox(p1::EGSParticle, p2::EGSParticle) = p1 === p2

function Base.propertynames(o::EGSParticle)
    (:latch, :new_history, :E, :x, :y, :u, :v, :w, :weight, :zlast)
end

function Setfield.setproperties(o::EGSParticle, props)
    EGSParticle(
        get(props, :latch, o.latch),
        get(props, :new_history, o.new_history),
        get(props, :E, o.E),
        get(props, :x, o.x),
        get(props, :y, o.y),
        get(props, :u, o.u),
        get(props, :v, o.v),
        get(props, :w, o.w),
        get(props, :weight, o.weight),
        get(props, :zlast, o.zlast),
    )

end

function EGSParticle(latch::Latch, new_history::Bool, E, x, y, u, v, w, weight, zlast)
    @argcheck weight >= 0
    @argcheck E >= 0
    @argcheck Float32(u^2 + v^2 + w^2) ≈ 1
    charge = latch.charge
    E_rest = rest_energy_by_charge(charge)
    E_tot = kin2total(Float32(E), E_rest)
    _E = Float32((-1)^new_history * E_tot)
    _weight = Float32(sign(w) * weight)
    EGSParticle(latch, _E, Float32(x), Float32(y), Float32(u), Float32(v), _weight, zlast)
end

function EGSParticle(;latch , new_history=true, E,x,y,u,v,w,weight=1f0,zlast=nothing)
    EGSParticle(latch, new_history, E, x, y, u, v, w, weight, zlast)
end

function kwshow(io::IO, o)
    print(io, typeof(o).name, "(")
    for pname in propertynames(o)
        pval = getproperty(o, pname)
        print(io, string(pname), "=")
        show(io, pval)
        print(io, ", ")
    end
    print(io, ")")
end

Base.show(io::IO, o::EGSParticle) = kwshow(io, o)

@inline function Base.getproperty(o::EGSParticle, s::Symbol)
    if s == :latch
        get_latch(o)
    elseif s == :E
        get_E(o)
    elseif s == :x
        get_x(o)
    elseif s == :y
        get_y(o)
    elseif s == :u
        get_u(o)
    elseif s == :v
        get_v(o)
    elseif s == :w
        get_w(o)
    elseif s == :weight
        get_weight(o)
    elseif s == :zlast
        get_zlast(o)
    elseif s == :new_history
        get_new_history(o)
    else
        throw(ErrorException("$o does not have property $s"))
    end
end
        
function kin2total(Ekin::Float32, E_rest::Float64)
    Float32(Float64(Ekin) + E_rest)
end

function total2kin(Etotal::Float32, E_rest::Float64)
    Float32(Float64(Etotal) - E_rest)
end

function rest_energy_by_charge(charge::Int)
    ifelse(charge == 0, 0., 0.511)
end

get_latch(o::EGSParticle) = getfield(o, :_latch)
function get_E(o::EGSParticle) 
    E_tot = abs(getfield(o, :_E))
    E_rest = rest_energy_by_charge(o.latch.charge)
    total2kin(E_tot, E_rest)
end

get_x(o::EGSParticle) = getfield(o, :_x)
get_y(o::EGSParticle) = getfield(o, :_y)
get_u(o::EGSParticle) = getfield(o, :_u)
get_v(o::EGSParticle) = getfield(o, :_v)

get_weight(o::EGSParticle) = abs(getfield(o, :_weight))
get_zlast(o::EGSParticle)  = getfield(o, :_zlast)
get_new_history(o::EGSParticle) = signbit(getfield(o, :_E))

function get_w(o::EGSParticle)
    u = Float64(get_u(o))
    v = Float64(get_v(o))
    sign_w = sign(getfield(o, :_weight))
    w64 = sign_w * sqrt(1 - u^2 - v^2)
    Float32(w64)
end

isphoton(o::EGSParticle) = o.latch.charge == 0
iselectron(o::EGSParticle) = o.latch.charge == -1
ispositron(o::EGSParticle) = o.latch.charge == 1

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
    total_size  = filesize(io)
    P = ptype(h)
    len = Int64(filesize(io) / sizeof(P)) - 1
    @assert len == h.particlecount
    buffer = Base.RefValue{P}()
    EGSPhspIterator(io, h, buffer, len)
end

function Base.iterate(iter::EGSPhspIterator)
    # skip header
    pos = sizeof(ptype(iter.header))
    seek(iter.io, pos)
    _iterate(iter)
end

@inline function _iterate(iter::EGSPhspIterator)
    if eof(iter.io)
        nothing
    else
        p = read!(iter.io, iter.buffer)[]
        dummy_state = nothing
        p, dummy_state
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
    function EGSWriter{P}(io::I, particlecount, photoncount,
                       max_E_kin, min_E_kin_electrons,
                       originalcount) where {P,I}

        w = new{P,I}(io, particlecount, photoncount,
                       max_E_kin, min_E_kin_electrons,
                       originalcount)
        finalizer(close, w)
        w
    end
end

# TODO looks like not invented here
writebytes(io::IO, l::Latch) = write(io, getfield(l, :_data))
writebytes(io::IO, x) = write(io, x)
writebytes(io::IO, ::Nothing) = 0
function writebytes(io::IO, p::EGSParticle)
    ret = 0
    ret += writebytes(io, getfield(p, :_latch))
    ret += writebytes(io, getfield(p, :_E))
    ret += writebytes(io, getfield(p, :_x))
    ret += writebytes(io, getfield(p, :_y))
    ret += writebytes(io, getfield(p, :_u))
    ret += writebytes(io, getfield(p, :_v))
    ret += writebytes(io, getfield(p, :_weight))
    ret += writebytes(io, getfield(p, :_zlast))
    ret
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
    writebytes(w.io, p)
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
    w = EGSWriter{P}(io, Int32(0),Int32(0),Float32(-Inf),Float32(Inf),Float32(1.))
    h = create_header(w)
    write_header(io, h)
    w
end

function Base.flush(w::EGSWriter)
    if isopen(w.io)
        h = create_header(w)
        pos = position(w.io)
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
