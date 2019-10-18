using ArgCheck
using StaticArrays

export StaticIAEAHeader
const LEGAL_RECORD_CONSTANT_NAMES = (:typ, :E, :x, :y, :z, :u, :v, :weight)

function validate_record_constants(::Type{Bool}, R::Type{<:NamedTuple})
    issubset(fieldnames(R) , LEGAL_RECORD_CONSTANT_NAMES) || return false
    legal_types = (typ = Int8, E=Float32, x=Float32, y=Float32, z=Float32, u=Float32, v=Float32, weight=Float32)
    for (field, T) in map(=>, fieldnames(R), fieldtypes(R))
        T === legal_types[field] || return false
    end
    return true
end

struct StaticIAEAHeader{record_constants, Nf, Ni}
    function StaticIAEAHeader{record_constants, Nf, Ni}() where {record_constants, Nf, Ni}
        @argcheck Ni isa Int
        @argcheck Nf isa Int
        @argcheck record_constants isa NamedTuple
        @argcheck Ni >= 0
        @argcheck Nf >= 0
        @argcheck validate_record_constants(Bool, typeof(record_constants))
        new{record_constants, Nf, Ni}()
    end
end

function StaticIAEAHeader(record_constants::NamedTuple, Nf::Int, Ni::Int)
    StaticIAEAHeader{record_constants, Nf, Ni}
end

function unsafe_getbyoffset(::Type{T}, s::S, offset::Int) where {T, S}
    rt = Ref{T}()
    rs = Ref{S}(s)
    GC.@preserve rt rs begin
        pt = Ptr{UInt8}(Base.unsafe_convert(Ref{T}, rt))
        ps = Ptr{UInt8}(Base.unsafe_convert(Ref{S}, rs)) + offset
        Base._memcpy!(pt, ps, sizeof(T))
    end
    return rt[] 
end

function check_getbyoffset(T, s, offset)
    S = typeof(s)
    isbitstype(T) || throw(ArgumentError("Can only cast into bitstype."))
    isbitstype(S) || throw(ArgumentError("Can only cast from bitstype."))
    @assert offset >= 0
    sizeof(T) + offset <= sizeof(S) || throw(ArgumentError("Can only cast between types of equal size."))
end

function getbyoffset(T, s, offset)
    @boundscheck check_getbyoffset(T, s, offset)
    unsafe_getbyoffset(T, s, offset)
end

get_record_constants(::Type{StaticIAEAHeader{rc, Nf, Ni}}) where {rc, Nf, Ni} = rc
get_Ni(::Type{StaticIAEAHeader{rc, Nf, Ni}}) where {rc, Nf, Ni} = Ni
get_Nf(::Type{StaticIAEAHeader{rc, Nf, Ni}}) where {rc, Nf, Ni} = Nf


function compute_field_offsets_and_size(record_constants::NamedTuple, Nf::Int, Ni::Int)::NamedTuple
    pairs = []
    offset = 0
    for (fieldname, fieldsize) in [
            :typ => 1,
            :E => 4,
            :x => 4, :y => 4, :z => 4,
            :u => 4, :v => 4,
            :weight => 4,
            :Nf => 4*Nf,
            :Ni => 4*Ni,
        ]
        if !haskey(record_constants, fieldname)
            push!(pairs, fieldname => offset)
            offset += fieldsize
        end
    end
    push!(pairs, :end => offset)
    (;pairs...)
end

function compute_field_offsets_and_size(::Type{StaticIAEAHeader{rc, Nf, Ni}}) where {rc, Nf, Ni}
    compute_field_offsets_and_size(rc, Nf, Ni)
end

@generated function field_offset(H::StaticIAEAHeader, ::Val{field})::Int where {field}
    table = compute_field_offsets_and_size(H)
    @assert field isa Symbol
    rc = get_record_constants(H)
    if haskey(rc, field)
        -1
    else
        table[field]
    end
end

@generated function sizeof_ptype(h::StaticIAEAHeader)
    table = compute_field_offsets_and_size(h)
    quote
        $table[:end]
    end
end

struct CompressedIAEAParticle{H<:StaticIAEAHeader, N}
    header::H
    data::NTuple{N, UInt8}
end

function ptype(H::Type{<:StaticIAEAHeader})
    N = sizeof_ptype(H())
    CompressedIAEAParticle{H, N}
end

get_typ8(    p::CompressedIAEAParticle) = _get_typ_field(p, Int8  , Val(:typ))
get_Esigned(     p::CompressedIAEAParticle) = _get_typ_field(p, Float32, Val(:E  ))

get_x(      p::CompressedIAEAParticle) = _get_typ_field(p, Float32, Val(:x  ))
get_y(      p::CompressedIAEAParticle) = _get_typ_field(p, Float32, Val(:y  ))
get_z(      p::CompressedIAEAParticle) = _get_typ_field(p, Float32, Val(:z  ))
     
get_u(      p::CompressedIAEAParticle) = _get_typ_field(p, Float32, Val(:u  ))
get_v(      p::CompressedIAEAParticle) = _get_typ_field(p, Float32, Val(:v  ))
get_weight( p::CompressedIAEAParticle) = _get_typ_field(p, Float32, Val(:weight))

function get_extra_floats(p::CompressedIAEAParticle{StaticIAEAHeader{rc, Nf, Ni}}) where {rc, Nf, Ni}
    T = NTuple{Nf, Float32}
    _get_typ_field(p, Tf, Val(:extra_floats))
end

function get_extra_ints(p::CompressedIAEAParticle{StaticIAEAHeader{rc, Nf, Ni}}) where {rc, Nf, Ni}
    T = NTuple{Nf, Int32}
    _get_typ_field(p, T, Val(:extra_ints))
end

function direction(p::CompressedIAEAParticle)
    u = get_u(p)
    v = get_v(p)
    typ8::Int8 = get_typ8(p)
    sign_w = Float32(-1)^(typ8 < 0)
    u,v,w = compute_u_v_w(u,v,sign_w)
    @SVector[u,v,w]
end

get_w(p::CompressedIAEAParticle) = direction(p)[3]

get_new_history(p::CompressedIAEAParticle) = get_Esigned(p) < 0
get_E(p::CompressedIAEAParticle) = abs(get_Esigned(p))

function get_typ(p::CompressedIAEAParticle)
    typ8 = get_typ8(p)
    ParticleType(abs(typ8))
end

@generated function _get_typ_field(p::CompressedIAEAParticle{H}, ::Type{T}, ::Val{field}) where {H,T, field}
    rc = get_record_constants(H)
    if haskey(rc, field)
        ret = rc[field]::T
    else
        ret = quote
            offset = field_offset($(H()), $(Val(field)))
            return getbyoffset(T, p, offset)
        end
    end
    return ret
end

const COMPRESSED_IAEA_PARTICLE_PROPERTY_NAMES = (
    :typ,
    :E,
    :weight,
    :x,
    :y,
    :z,
    :u,
    :v,
    :w,
    :new_history,
    :extra_floats,
    :extra_ints,
)

function Base.propertynames(o::CompressedIAEAParticle)
    COMPRESSED_IAEA_PARTICLE_PROPERTY_NAMES
end

function Base.getproperty(o::CompressedIAEAParticle, prop::Symbol)
    if prop === :typ
        get_typ(o)
    elseif prop === :E
        get_E(o)
    elseif prop === :weight
        get_weight(o)
    elseif prop === :x
        get_x(o)
    elseif prop === :y
        get_y(o)
    elseif prop === :z
        get_z(o)
    elseif prop === :u
        get_u(o)
    elseif prop === :v
        get_v(o)
    elseif prop === :w
        get_w(o)
    elseif prop === :new_history
        get_new_history(o)
    elseif prop === :extra_floats
        get_extra_float(o)
    elseif prop === :extra_ints
        get_extra_ints(o)
    else
        msg = "Unknown property $prop"
        throw(ArgumentError(msg))
    end
end
