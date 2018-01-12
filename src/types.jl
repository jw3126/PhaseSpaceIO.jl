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
        new(typ, E, weight, x,y,z, u,v,w, new_history, extra_floats, extra_ints)
    end
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

struct Header{Nf, Ni}

    # default values
    x::Nullable{Float32}
    y::Nullable{Float32}
    z::Nullable{Float32}
    
    u::Nullable{Float32}
    v::Nullable{Float32}
    w::Nullable{Float32}
    
    weight::Nullable{Float32}

end

struct PhaseSpace{H <: Header, P}
    header::H
    particles::P
    function PhaseSpace{H,P}(header, particles) where{H, P}
        @argcheck eltype(particles) == ptype(H)
        new(header, particles)
    end
end

PhaseSpace(h,ps) = PhaseSpace{typeof(h), typeof(ps)}(h,ps)

function Header{Nf, Ni}() where {Nf, Ni}
    args = fill(Nullable{Float32}(), 7)
    Header{Nf, Ni}(args...)
end
