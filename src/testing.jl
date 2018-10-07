module Testing
using PhaseSpaceIO: Particle, ParticleType
export arbitrary

function arbitrary(::Type{Particle{Nf,Ni}}) where {Nf, Ni}
    typ = rand([instances(ParticleType)...])
    E = 100*rand(Float32)
    weight = rand(Float32)
    x = randn(Float32)
    y = randn(Float32)
    z = randn(Float32)
    u = randn(Float32)
    v = randn(Float32)
    w = randn(Float32)
    scale = 1/sqrt(u^2 + v^2 + w^2)
    u *= scale
    v *= scale
    w *= scale
    new_history  = rand(Bool)
    extra_floats = tuple(randn(Float32, Nf)...)
    extra_ints   = tuple(rand(Int32, Ni)...)
    Particle{Nf,Ni}(typ,
                    E,
                    weight,
                    x,y,z,
                    u,v,w,
                    new_history,
                    extra_floats,
                    extra_ints)
end
end
