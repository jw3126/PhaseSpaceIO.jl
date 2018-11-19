const ByteBuffer = AbstractVector{UInt8}

@generated function readtuple(io::IO, ::Type{T}) where {T <: Tuple}
    args = [:(read(io, $Ti)) for Ti ∈ T.parameters]
    Expr(:call, :tuple, args...)
end

@generated function readbuf!( ::Type{T}, buf::ByteBuffer) where {T <: Tuple}
    args = [:(readbuf!($Ti, buf)) for Ti ∈ T.parameters]
    Expr(:call, :tuple, args...)
end

function readbuf!(::Type{T}, buf::ByteBuffer) where {T}
    @argcheck sizeof(T) == sizeof(UInt32)
    reinterpret(T, readbuf!(UInt32, buf))
end

function readbuf!(::Type{Nothing}, buf::ByteBuffer)
    nothing
end

function readbuf!(::Type{UInt8}, buf::ByteBuffer)
    popfirst!(buf)
end
function readbuf!(T::Type{Int8}, buf::ByteBuffer)
    reinterpret(T, readbuf!(UInt8, buf))
end

function readbuf!(::Type{UInt32}, buf::ByteBuffer)
    b4 = UInt32(popfirst!(buf)) << 0
    b3 = UInt32(popfirst!(buf)) << 8
    b2 = UInt32(popfirst!(buf)) << 16
    b1 = UInt32(popfirst!(buf)) << 24
    b1 + b2 + b3 + b4
end

function bytelength(io::IO)
    init_pos = position(io)
    seekstart(io)
    start_pos = position(io)
    seekend(io)
    end_pos = position(io)
    seek(io, init_pos)
    end_pos - start_pos
end

function getbit(x::Integer, i)
    (x & (1 << i)) == (1 << i)
end

function setbit(x::Integer, val::Bool, i)
    T = typeof(x)
    newbit = T(val)
    mask = (T(-newbit) ⊻ x) & (T(1) << i)
    x ⊻ mask
end
