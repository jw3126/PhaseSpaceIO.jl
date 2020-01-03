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
    propagate_z(p, z_from, z_to)

Propagate particle `p` from `z = z_from` to `z = z_to`.
"""
function propagate_z(p, z_from, z_to)
    pos = position(p)
    is3d = length(pos) == 3
    if z_from == nothing
        z_from = pos[3]
    end
    if is3d
        @check z_from ≈ pos[3]
    end
    t = (z_to - z_from) / p.w

    if is3d
        dir = direction(p)
    else
        u,v,w = direction(p)
        dir = @SVector[u,v]
    end
    p2 = @set position(p) = pos + t * dir
    if is3d
        if z_to == 0
            @check abs(z_to - p2.z) < sqrt(eps(Float32))
        else
            @check z_to ≈ p2.z
        end
    end
    p2
end
