__precompile__()
module PhaseSpaceIO
using ArgCheck
using DataStructures

include("iohelpers.jl")
include("types.jl")
include("load_header.jl")
include("load_phsp.jl")
include("write.jl")
include("egs.jl")
include("abstract.jl")
include("api.jl")
include("experimental.jl")
include("getters.jl")
include("testing.jl")
include("deprecate.jl")
include("download.jl")

end
