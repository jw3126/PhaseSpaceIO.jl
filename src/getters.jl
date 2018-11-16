module Getters
using PhaseSpaceIO: IAEAParticle

for field in fieldnames(IAEAParticle{0,0})
    @eval ($field)(p) = p.$field
    @eval export $field
end

export energy
energy(p) = E(p)*weight(p)

end
