export particle_type

const EXT_HEADER = ".IAEAheader"
const EXT_PHSP   = ".IAEAphsp"
struct IAEAPath
    header::String
    phsp::String
end
IAEAPath(path::IAEAPath) = path

function IAEAPath(path::AbstractString)
    stem, ext = splitext(path)
    if !(ext in (EXT_HEADER, EXT_PHSP))
        stem = path
    end
    header_path = stem * EXT_HEADER
    phsp_path = stem * EXT_PHSP
    IAEAPath(header_path, phsp_path)
end

function Base.rm(path::IAEAPath;kw...)
    rm(path.header;kw...)
    rm(path.phsp;kw...)
end

struct IAEAParticle{Nf, Ni} <: AbstractIAEAParticle
    typ::ParticleType
    E::Float32
    weight::Float32
    x::Float32
    y::Float32
    z::Float32
    u::Float32
    v::Float32
    w::Float32
    new_history::Bool
    extra_floats::NTuple{Nf, Float32}
    extra_ints::NTuple{Ni, Int32}
end

function equal_properties(p1::AbstractIAEAParticle, p2::AbstractIAEAParticle)
    p1.typ    == p2.typ || return false
    p1.E      == p2.E || return false
    p1.weight == p2.weight || return false
    p1.x      == p2.x || return false
    p1.y      == p2.y || return false
    p1.z      == p2.z || return false
    p1.u      == p2.u || return false
    p1.v      == p2.v || return false
    p1.w      == p2.w || return false
    p1.new_history  == p2.new_history || return false
    p1.extra_floats == p2.extra_floats || return false
    p1.extra_ints   == p2.extra_ints || return false
    return true
end

function Base.:(==)(p1::AbstractIAEAParticle, p2::AbstractIAEAParticle)
    equal_properties(p1, p2)
end

function IAEAParticle(typ, E, weight, 
                          x,y,z, 
                          u,v,w, 
                          new_history, 
                          extra_floats::NTuple{Nf,Float32},
                          extra_ints::NTuple{Ni,Int32}) where {Nf, Ni}

    IAEAParticle{Nf, Ni}(typ, E, weight,
                     x,y,z, u,v,w,
                     new_history,
                     extra_floats, extra_ints)
end

function IAEAParticle(;typ,E,weight=1,x,y,z,
                  u,v,w,
                  new_history=true,
                  extra_floats=(),
                  extra_ints=()
                 )
    IAEAParticle(typ, E, weight,
                     x,y,z, u,v,w,
                     new_history,
                     extra_floats, extra_ints)
end

particle_type(p::IAEAParticle) = p.typ
function Base.show(io::IO, p::IAEAParticle)
    kwshow(io, p)
end

function Base.isapprox(p1::AbstractIAEAParticle, p2::AbstractIAEAParticle;kw...)
    p1.typ == p2.typ  &&
    p1.new_history   == p2.new_history    &&
    p1.extra_floats  == p2.extra_floats   &&
    p1.extra_ints    == p2.extra_ints     &&
    isapprox(p1.E,      p2.E;      kw...) &&
    isapprox(p1.weight, p2.weight; kw...) &&
    isapprox(position(p1), position(p2); kw...) &&
    isapprox(direction(p1), direction(p2); kw...)
end

struct IAEAHeader{Nf, Ni, NT<:NamedTuple}
    record_contents::NT
    attributes::OrderedDict{Symbol, String}
end

function IAEAHeader{Nf, Ni}(
        rc::NamedTuple=NamedTuple(),
        raw=OrderedDict{Symbol,String}()) where {Nf, Ni}

    for (keyword,val) in pairs(rc)
        @argcheck keyword in [:x, :y, :z, :u, :v, :w, :weight]
    end
    rc32 = map(Float32, rc)
    NT = typeof(rc32)
    IAEAHeader{Nf, Ni,NT}(rc32, raw)
end

function get_originalcount(o::IAEAHeader)::Float64
    parse(Float64, o.attributes[:ORIG_HISTORIES])
end

struct IAEAPhspIterator{H,I<:IO} <: AbstractPhspIterator
    io::I
    header::H
    length::Int64
end

function IAEAPhspIterator(io::IO,h::IAEAHeader)
    H = typeof(h)
    I = typeof(io)
    bl = bytelength(io)
    length = Int64(bl / ptype_disksize(h))
    IAEAPhspIterator{H,I}(io, h, length)
end

function Base.eltype(::Type{<:IAEAPhspIterator{H}}) where {H}
    ptype(H)
end
