# PhaseSpaceIO

[![Build Status](https://travis-ci.org/jw3126/PhaseSpaceIO.jl.svg?branch=master)](https://travis-ci.org/jw3126/PhaseSpaceIO.jl)
[![codecov.io](https://codecov.io/github/jw3126/PhaseSpaceIO.jl/coverage.svg?branch=master)](http://codecov.io/github/jw3126/PhaseSpaceIO.jl?branch=master)

## Usage

```julia
julia> using PhaseSpaceIO

julia> path = joinpath(dirname(pathof(PhaseSpaceIO)), "..", "test", "assets","some_file.IAEAphsp");
julia> ps = phsp_iterator(collect,path)
1-element Array{Particle{0,1},1}:
 Particle{0,1}(photon::ParticleType = 1, 1.0f0, 2.0f0, 3.0f0, 4.0f0, 5.0f0, 0.53259337f0, 0.3302265f0, -0.7792912f0, true, (), (13,))

julia> dir = mkpath(tempname())
"/tmp/juliavg1Oci"

julia> readdir(dir)
0-element Array{String,1}

julia> path = joinpath(dir, "hello")
"/tmp/juliavg1Oci/hello"

julia> phsp_writer(path, RecordContents{0,1}()) do w
           for p in ps
               write(w,p)
           end
       end

julia> readdir(dir)
2-element Array{String,1}:
 "hello.IAEAheader"
 "hello.IAEAphsp"  
```
