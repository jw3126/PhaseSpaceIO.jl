export iaea_iterator
export iaea_writer
export egs_iterator

function iaea_writer end

@noinline function _apply(f::F, iter) where {F}
    f(iter)
end
iaea_iterator(path) = iaea_iterator(IAEAPath(path))

function iaea_iterator(path::IAEAPath)
    @argcheck ispath(path.header)
    @argcheck ispath(path.phsp)
    h = load(path.header, RecordContents)
    io = open(path.phsp)
    IAEAPhspIterator(io,h)
end

function egs_iterator(path::AbstractString)
    io = open(path, "r")
    egs_iterator(io)
end

for xxx_iterator in [:egs_iterator, :iaea_iterator]
    @eval function $(xxx_iterator)(f, path)
        iter = $(xxx_iterator)(path)
        ret = _apply(f, iter)
        close(iter)
        ret
    end
end
