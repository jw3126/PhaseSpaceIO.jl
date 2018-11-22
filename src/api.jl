export phsp_iterator
export iaea_iterator
export iaea_writer
export egs_iterator
export egs_writer

function iaea_writer end

iaea_iterator(path) = iaea_iterator(IAEAPath(path))

function iaea_iterator(path::IAEAPath)
    @argcheck ispath(path.header)
    @argcheck ispath(path.phsp)
    h = load(path.header, RecordContents)
    io = FastReadIO(open(path.phsp))
    IAEAPhspIterator(io,h)
end

function egs_iterator(path::AbstractString)
    io = FastReadIO(open(path, "r"))
    egs_iterator(io)
end

function phsp_iterator(f, path::IAEAPath)
    iaea_iterator(f, path)
end

function phsp_iterator(f, path::AbstractString)
    stem, ext = splitext(path)
    if startswith(ext, ".IAEA")
        iaea_iterator(f, path)
    elseif startswith(ext, ".egsphsp")
        egs_iterator(f, path)
    else
        msg = "Cannot guess format from file extension for $path."
        throw(ArgumentError(msg))
    end
end

for xxx_iterator in [:egs_iterator, :iaea_iterator]
    @eval function $(xxx_iterator)(f, path)
        iter = $(xxx_iterator)(path)
        ret = call_fenced(f, iter)
        close(iter)
        ret
    end
end
