__precompile__()
module PhaseSpaceIO
using ArgCheck
using DataStructures

include("abstract.jl")
include("iohelpers.jl")
include("common.jl")
include("iaea/iaea.jl")
include("egs/egs.jl")
include("api.jl")
include("experimental.jl")
include("getters.jl")
include("testing.jl")
include("deprecate.jl")
include("download.jl")
include("conversion.jl")

include("staticarrays.jl")
include("transforms.jl")

end#module
