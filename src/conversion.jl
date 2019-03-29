using Setfield
using ArgCheck

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

function phsp_convert(src::AbstractString, dst::IAEAPath;  z)
    egs_iterator(src) do iter
        phsp_convert(iter, dst, z=z)
    end
end

function phsp_convert(iter, dst::IAEAPath; z)
    header = IAEAHeader{0,0}()
    iaea_writer(dst, header) do w
        for p in iter
            write(w, to_iaea(p, z=z))
        end
    end
end
