using StaticArrays: @SVector, normalize
using Accessors: Accessors, setproperties
export position
export direction

position(o) = o.position
direction(o) = o.direction
set_position(o, pos)  = setproperties(o, (position=pos,))
set_direction(o, dir) = setproperties(o, (direction=dir,))
set_position_direction(o, pos, dir) = setproperties(o, (position=pos, direction=dir))

Accessors.set(o, ::typeof(position), val) = set_position(o, val)
Accessors.set(o, ::typeof(direction), val) = set_direction(o, val)

function direction(p::AbstractParticle)
    @SVector [p.u, p.v, p.w]
end

has_z(::Type{<:AbstractParticle}) = true
has_z(::Type{<:EGSParticle})      = false

function position(p::P, z=nothing) where {P <: AbstractParticle}
    if (z == nothing)
        if has_z(P)
            return @SVector[p.x, p.y, p.z]
        else
            return @SVector[p.x, p.y]
        end
    else
        if has_z(P)
            @argcheck p.z ≈ z
            z = p.z
        end
        return @SVector[p.x, p.y, z]
    end
end

function set_direction(p::AbstractParticle, dir)
    u,v,w = dir
    setproperties(p, (u=u,v=v,w=w))
end

@inline function _xyz(pos, z)
    len = length(pos)
    if len == 3
        return pos
    elseif len == 2
        x,y = pos
        return x,y,z
    else
        throw(ArgumentError("Wrong length $(len))"))
    end
end

function set_position(p::AbstractParticle, pos)
    x,y,z = _xyz(pos, nothing)
    setproperties(p, (x=x,y=y,z=z))
end

function set_position(p::CompressedIAEAParticle, pos)
    set_position(IAEAParticle(p), pos)
end
function set_direction(p::CompressedIAEAParticle, dir)
    set_direction(IAEAParticle(p), dir)
end
function set_position_direction(p::CompressedIAEAParticle, pos, dir)
    set_position_direction(IAEAParticle(p), pos, dir)
end

function set_position_direction(p::AbstractParticle, pos, dir)
    x,y,z = _xyz(pos, nothing)
    u,v,w = dir
    setproperties(p, (x=x,y=y,z=z,u=u,v=v,w=w))
end
