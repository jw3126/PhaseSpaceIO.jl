export iaea_iterator
export iaea_writer

function iaea_writer end

@noinline function _apply(f,iter::PhaseSpaceIterator)
    f(iter)
end
function iaea_iterator(f, path)
    phsp = iaea_iterator(path)
    ret = _apply(f,phsp)
    close(phsp)
    ret
end
iaea_iterator(path) = iaea_iterator(IAEAPath(path))

function iaea_iterator(path::IAEAPath)
    @argcheck ispath(path.header)
    @argcheck ispath(path.phsp)
    h = load(path.header, RecordContents)
    io = open(path.phsp)
    PhaseSpaceIterator(io,h)
end
