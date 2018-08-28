export Particle, ParticleType, Header, PhaseSpace
export photon, electron, positron, neutron, proton

@enum ParticleType photon=1 electron=2 positron=3 neutron=4 proton=5

struct Particle{Nf, Ni}
    particle_type::ParticleType
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
    function Particle{Nf, Ni}(typ, E, weight, 
                              x,y,z, 
                              u,v,w, 
                              new_history, 
                              extra_floats, extra_ints) where {Nf, Ni}
        # the unit direction assert is expensive 
        # and allocated on julia v0.6 if phrased as argcheck
        epsilon = Float32(1e-6)
        @assert abs(u^2 + v^2 + w^2 -1) < epsilon
        # @assert abs(u^2 + v^2 + w^2) ≈ 1
        @argcheck E >= 0.
        @argcheck weight >= 0.
        new(ParticleType(typ),
            E, weight,
            x,y,z, u,v,w,
            new_history, extra_floats, extra_ints)
    end
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


function Base.isapprox(p1::Particle, p2::Particle)
    p1.particle_type == p2.particle_type &&
    isapprox(p1.E, p2.E) &&
    isapprox(p1.weight, p2.weight) &&
    isapprox(p1.x, p2.x) &&
    isapprox(p1.y, p2.y) &&
    isapprox(p1.z, p2.z) &&
    isapprox(p1.u, p2.u) &&
    isapprox(p1.v, p2.v) &&
    isapprox(p1.w, p2.w) &&
    p1.new_history == p2.new_history &&
    p1.extra_floats == p2.extra_floats &&
    p1.extra_ints == p2.extra_ints
end

for pt in instances(ParticleType)
    fname = Symbol("is", pt)
    @eval $fname(x::Particle) = x.particle_type == $pt
    eval(Expr(:export, fname))
end

struct Header{Nf, Ni, NT<:NamedTuple}
    default_particle_values::NT
end

function Header{Nf, Ni}(;
                        kw...
                       ) where {Nf, Ni}
    for (keyword,val) in kw
        @argcheck keyword in [:x, :y, :z, :u, :v, :w, :weight]
    end
    default_particle_values = map(Float32, NamedTuple(kw...))
    NT = typeof(default_particle_values)
    Header{Nf, Ni,NT}(default_particle_values)
end

abstract type AbstractPhaseSpace{H <: Header, P} end

Base.eltype(::Type{AbstractPhaseSpace{H,P}}) where {H,P} = P

struct PhaseSpaceIterator{H,P,I<:IO} <: AbstractPhaseSpace{H,P}
    io::I
    header::H
    buf::Vector{UInt8}
    bufsize::Int
end

function PhaseSpaceIterator(io::IO,h::Header)
    H = typeof(h)
    P = ptype(h)
    I = typeof(io)
    buf = Vector{UInt8}()
    bufsize = compressed_particle_sizeof(h)
    PhaseSpaceIterator{H,P,I}(io, h,buf,bufsize)
end
function read_next_nullable(iter::PhaseSpaceIterator)
end
function Base.iterate(iter::PhaseSpaceIterator, state...)
    io = iter.io
    h = iter.header
    P = ptype(h)
    if eof(iter.io)
        nothing
    else
        p = read_particle_explicit_buf(io, h, iter.buf, iter.bufsize)
        dummy_state = nothing 
        p, dummy_state
    end
end
function Base.iteratorsize(iter::AbstractPhaseSpace) 
    Base.SizeUnknown()
end
function Base.iteratorsize(iter::Base.Iterators.Take{<:AbstractPhaseSpace}) 
    Base.iteratorsize(iter.xs)
end
function Base.close(iter::PhaseSpaceIterator)
    close(iter.io)
end
