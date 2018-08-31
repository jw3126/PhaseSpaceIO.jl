__precompile__()
module PhaseSpaceIO
using ArgCheck
# macro argcheck(code)
#     quote end
# end
using DataStructures
using QuickTypes

include("types.jl")
include("load_header.jl")
include("load_phsp.jl")
include("write.jl")
include("api.jl")
include("download.jl")
include("experimental.jl")
include("getters.jl")
include("testing.jl")
include("deprecate.jl")

end
