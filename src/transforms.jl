using CoordinateTransformations

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
