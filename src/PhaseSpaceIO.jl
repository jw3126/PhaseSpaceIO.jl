__precompile__()
module PhaseSpaceIO
using ArgCheck
using DataStructures
using QuickTypes

include("types.jl")
include("load_header.jl")
include("load_phsp.jl")
include("api.jl")
end
