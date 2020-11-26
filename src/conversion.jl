module Conversion

using DataStructures
using PhaseSpaceIO
using Accessors
using ArgCheck

function compute_extra_ints(p::EGSParticle)::NTuple{1, Int32}
    ulatch = UInt32(p.latch)
    ilatch = Int32(ulatch)
    (ilatch,)
end

function compute_extra_floats(p::EGSParticle{Nothing})::NTuple{0, Float32}
    ()
end

function compute_extra_floats(p::EGSParticle{Float32})::NTuple{1, Float32}
    (p.zlast,)
end

function to_iaea(p::EGSParticle; z)
    IAEAParticle(
        typ = particle_type(p),
        x=p.x,
        y=p.y,
        z=z,
        u=p.u,
        v=p.v,
        w=p.w,
        E=p.E,
        new_history=p.new_history,
        weight=p.weight,
        extra_floats=compute_extra_floats(p),
        extra_ints=compute_extra_ints(p),
    )
end

function to_egs(p::IAEAParticle)
    typ = p.typ
    q = if typ == photon
        0
    elseif typ == electron
        -1
    elseif typ == positron
        1
    else
        msg = "Cannot convert particle of type = $typ to EGS"
        throw(ArgumentError(msg))
    end
    EGSParticle(
        latch=Latch(charge=q),
        new_history=p.new_history,
        x=p.x,
        y=p.y,
        u=p.u,
        v=p.v,
        w=p.w,
        E=p.E,
        weight=p.weight,
    )
end

function phsp_convert(src::AbstractString, dst::IAEAPath; z)
    phsp_convert([src], dst, z=z)
end

function phsp_convert(srcs::AbstractVector{<:AbstractString}, dst::IAEAPath;  z)
    iters = map(egs_iterator, srcs)
    ret = phsp_convert(iters, dst, z=z)
    foreach(close, iters)
    ret
end

function _create_iaea_header(iters; z)
    iter = first(iters)
    originalcount = sum(iters) do iter
        iter.header.originalcount
    end
    nt = (z=z,)
    _Nf(::Type{EGSParticle{Nothing}}) = 0
    _Nf(::Type{EGSParticle{Float32}}) = 1
    Nf = _Nf(eltype(iter))
    H = IAEAHeader{1,Nf}
    d = OrderedDict(:ORIG_HISTORIES => string(originalcount))
    header = H(nt, d)
    return header
end

@noinline function phsp_append(writer, iter, z)
    for p in iter
        write(writer, to_iaea(p, z=z))
    end
end

@noinline function phsp_convert(iters, dst::IAEAPath; z)
    if isempty(iters)
        return
    end
    h = _create_iaea_header(iters, z=z)
    iaea_writer(dst, h) do w
        for iter in iters
            phsp_append(w, iter, z)
        end
    end
end

end#module
