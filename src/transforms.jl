using CoordinateTransformations
using Setfield

# P = AbstractParticle does not suffice
for P in [EGSParticle, IAEAParticle, CompressedIAEAParticle]
    @eval function (t::Translation)(p::$P)
        pos = t(position(p))
        set_position(p, pos)
    end
    @eval function (t::LinearMap)(p::$P)
        pos = t(position(p))
        dir = t(direction(p))
        set_position_direction(p, pos, dir)
    end
    @eval function (t::AffineMap)(p::$P)
        pos = t(position(p))
        dir = t.linear*direction(p)
        set_position_direction(p, pos, dir)
    end
end

"""
    propagate_z(p, z)

Propagate particle `p` such that `p.z=z`
"""
function propagate_z(p::P, z) where {P}
    if P <: AbstractParticle
        @argcheck has_z(P)
    end
    pos = position(p)
    dir = direction(p)
    z_to = z
    z_from = pos[3]
    t = (z_to - z_from) / dir[3]
    @set position(p) = pos + t * dir
end

export SetZ
"""

    SetZ(z)(p::EGSParticle)::EGSParticleZ

Set the `z` coordinate of `p`.
"""
struct SetZ
    z::Float32
end

(f::SetZ)(p::EGSParticle) = @set p.z = f.z
