export Particle, ParticleType, RecordContents, PhaseSpace
export photon, electron, positron, neutron, proton
export IAEAPath

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

@enum ParticleType photon=1 electron=2 positron=3 neutron=4 proton=5
Base.convert(::Type{ParticleType}, i::Integer) = ParticleType(i)

struct Particle{Nf, Ni}
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

function Particle(typ, E, weight, 
                          x,y,z, 
                          u,v,w, 
                          new_history, 
                          extra_floats::NTuple{Nf,Float32}, extra_ints::NTuple{Ni,Int32}) where {Nf, Ni}

    Particle{Nf, Ni}(typ, E, weight,
                     x,y,z, u,v,w,
                     new_history,
                     extra_floats, extra_ints)
end

function Particle(;typ,E,weight=1,x,y,z,
                  u,v,w,
                  new_history=true,
                  extra_floats=(),extra_ints=())
    Particle(typ, E, weight,
                     x,y,z, u,v,w,
                     new_history,
                     extra_floats, extra_ints)
end

function Base.show(io::IO, p::Particle)
    print(io, "Particle(typ=$(p.typ), E=$(p.E), weight=$(p.weight), x=$(p.x), y=$(p.y), z=$(p.z), u=$(p.u), v=$(p.v), w=$(p.w), new_history=$(p.new_history), extra_floats=$(p.extra_floats), extra_ints=$(p.extra_ints))")
end

function Base.isapprox(p1::Particle, p2::Particle;kw...)
    p1.typ == p2.typ  &&
    p1.new_history   == p2.new_history    &&
    p1.extra_floats  == p2.extra_floats   &&
    p1.extra_ints    == p2.extra_ints     &&
    isapprox(p1.E,      p2.E;      kw...) &&
    isapprox(p1.weight, p2.weight; kw...) &&
    isapprox([p1.x, p1.y, p1.z], [p2.x, p2.y, p2.z]; kw...) &&
    isapprox([p1.u, p1.v, p1.w], [p2.u, p2.v, p2.w]; kw...)
end

for pt in instances(ParticleType)
    fname = Symbol("is", pt)
    @eval $fname(x::Particle) = x.typ == $pt
    eval(Expr(:export, fname))
end

struct RecordContents{Nf, Ni, NT<:NamedTuple}
    data::NT
end

function RecordContents{Nf, Ni}(;
                        kw...
                       ) where {Nf, Ni}
    for (keyword,val) in kw
        @argcheck keyword in [:x, :y, :z, :u, :v, :w, :weight]
    end
    data = map(Float32, (;kw...))
    NT = typeof(data)
    RecordContents{Nf, Ni,NT}(data)
end

abstract type AbstractPhaseSpace{H <: RecordContents, P} end

Base.eltype(::Type{<:AbstractPhaseSpace{H,P}}) where {H,P} = P

struct PhaseSpaceIterator{H,P,I<:IO} <: AbstractPhaseSpace{H,P}
    io::I
    header::H
    # currently read(io, Float32) allocates,
    # but read!(io, buf) does not
    buf::Vector{UInt8}
    length::Int64
end

function bytelength(io::IO)
    init_pos = position(io)
    seekstart(io)
    start_pos = position(io)
    seekend(io)
    end_pos = position(io)
    seek(io, init_pos)
    end_pos - start_pos
end

Base.length(p::PhaseSpaceIterator) = p.length

function PhaseSpaceIterator(io::IO,h::RecordContents)
    H = typeof(h)
    P = ptype(h)
    I = typeof(io)
    buf = Vector{UInt8}()
    bl = bytelength(io)
    length = Int64(bl / compressed_particle_sizeof(h))
    PhaseSpaceIterator{H,P,I}(io, h,buf, length)
end

function Base.iterate(iter::PhaseSpaceIterator)
    seekstart(iter.io)
    _iterate(iter)
end
function Base.iterate(iter::PhaseSpaceIterator, state)
    _iterate(iter)
end

@inline function _iterate(iter::PhaseSpaceIterator)
    io = iter.io
    h = iter.header
    P = ptype(h)
    if eof(iter.io)
        nothing
    else
        p = read_particle_explicit_buf(io, h, iter.buf)
        dummy_state = nothing
        p, dummy_state
    end
end

function Base.IteratorSize(iter::AbstractPhaseSpace)
    Base.HasLength()
end
function Base.IteratorSize(iter::Base.Iterators.Take{<:AbstractPhaseSpace}) 
    Base.IteratorSize(iter.xs)
end
function Base.close(iter::PhaseSpaceIterator)
    close(iter.io)
end
