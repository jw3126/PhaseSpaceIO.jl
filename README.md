# PhaseSpaceIO

[![Build Status](https://travis-ci.org/jw3126/PhaseSpaceIO.jl.svg?branch=master)](https://travis-ci.org/jw3126/PhaseSpaceIO.jl)
[![codecov.io](https://codecov.io/github/jw3126/PhaseSpaceIO.jl/coverage.svg?branch=master)](http://codecov.io/github/jw3126/PhaseSpaceIO.jl?branch=master)

## Usage

```julia
using PhaseSpaceIO

path = joinpath(Pkg.dir("PhaseSpaceIO"),"test", "assets","some_file.IAEAphsp")
open_phsp(collect,path)
```
