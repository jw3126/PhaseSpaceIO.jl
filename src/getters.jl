module Getters
using PhaseSpaceIO: Particle

for field in fieldnames(Particle{0,0})
    @eval ($field)(p) = p.$field
    @eval export $field
end

export energy
energy(p) = E(p)*weight(p)

end
