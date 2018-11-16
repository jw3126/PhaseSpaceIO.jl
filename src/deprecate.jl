@deprecate phsp_iterator(args...) iaea_iterator(args...)
@deprecate phsp_writer(args...)   iaea_writer(args...)
@deprecate Particle IAEAParticle
@deprecate PhaseSpaceIterator IAEAPhspIterator
@deprecate PhaseSpaceWriter IAEAPhspWriter
@deprecate convert(::Type{ParticleType}, i::Integer) ParticleType(i)
