# PhaseSpaceIO

## Usage

```julia
using PhaseSpaceIO

path = joinpath(Pkg.dir("PhaseSpaceIO"),"test", "assets","some_file.IAEAphsp")
open_phsp(collect,path)
```
