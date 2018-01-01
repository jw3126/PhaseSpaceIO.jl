const EXT_HEADER = ".IAEAheader"
const EXT_PHSP   = ".IAEAphsp"

function load(path::AbstractString, T)
    open(path) do io
        load(io, T)
    end
end
function load(io::IO, ::Type{Header})
    read_header(io)
end
function load(path::AbstractString, ::Type{PhaseSpace})
    stem, ext = splitext(path)
    if !(ext in (EXT_HEADER, EXT_PHSP))
        stem = path
    end

    header_path = stem * EXT_HEADER
    phsp_path = stem * EXT_PHSP
    @argcheck ispath(header_path)
    @argcheck ispath(phsp_path)
    h = load(header_path, Header)
    ps = open(phsp_path) do io
        readphsp(io, h)
    end
    PhaseSpace(h, ps)
end
