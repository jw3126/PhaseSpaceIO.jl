export phsp_iterator
export phsp_writer

function phsp_writer end

@noinline function _apply(f,iter::PhaseSpaceIterator)
    f(iter)
end
function phsp_iterator(f, path)
    phsp = phsp_iterator(path)
    ret = _apply(f,phsp)
    close(phsp)
    ret
end
phsp_iterator(path) = phsp_iterator(IAEAPath(path))

function phsp_iterator(path::IAEAPath)
    @argcheck ispath(path.header)
    @argcheck ispath(path.phsp)
    h = load(path.header, RecordContents)
    io = open(path.phsp)
    PhaseSpaceIterator(io,h)
end
