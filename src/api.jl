export open_phsp
const EXT_HEADER = ".IAEAheader"
const EXT_PHSP   = ".IAEAphsp"

@noinline function _apply(f,iter::PhaseSpaceIterator)
    f(iter)
end
function open_phsp(f, path)
    phsp = open_phsp(path)
    ret = _apply(f,phsp)
    close(phsp)
    ret
end
function open_phsp(path)
    stem, ext = splitext(path)
    if !(ext in (EXT_HEADER, EXT_PHSP))
        stem = path
    end

    header_path = stem * EXT_HEADER
    phsp_path = stem * EXT_PHSP
    @argcheck ispath(header_path)
    @argcheck ispath(phsp_path)
    h = load(header_path, Header)
    io = open(phsp_path)
    PhaseSpaceIterator(io,h)
end
