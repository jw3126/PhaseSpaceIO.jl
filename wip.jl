using Revise
using PhaseSpaceIO
using PhaseSpaceIO: write_particle

struct IAEAIo{I<:IO, H}
    io_header::I
    io_phsp::I
    
    buf::Vector{UInt8}
    bufsize::Int
    
    header::H
end

function Base.open(path::IAEAPath, header = load(path.header, Header))
    io_header = open(path.header)
    io_phsp = open(path.phsp)
    buf = Vector{UInt8}()
    bufsize = compressed_particle_sizeof(header)
    IAEAIo(io_header, io_phsp, buf, bufsize, header)
end

function flush_header(io::IAEAIo)
    
    
end

for f in [:seekstart, :seekend, :position]
    @eval function Base.$f(io::IAEAIo)
        $f(io.io_phsp)
        io
    end
end

function Base.close(io::IAEAIo)
    flush_header(io)
    close(io.io_header)
    close(io.io_phsp  )
end

function total_particle_count(io::IAEAIo)
    byte_count = position(seekend(io))
    Int64(byte_count / bufsize)
end

function Base.write(io::IAEAIo, p::Particle)
    write_particle(io.io_phsp, p, io.header)
end

function Base.read(io::IAEAIo, ::Type{P}) where {P <: Particle}
    read_particle(io.io_phsp, io.header) :: P
end

struct Header{R}
    record_contents::R
    mandatory_attributes::Dict{String,String}
    optional_attributes::Dict{String,String}
end


h = Header(RecordContents{1,1}(x=1,y=2), Dict("IAEA_INDEX" => "mandatory"), Dict("optional" => "stuff"))

function show_key(io::IO, k)
    println(io,"$",k,":")
end
function show_val(io, v)
    println(io,v)
end
function show_kv(io::IO, k, v)
    k,v = p
    show_key(io,k)
    show_val(io,v)
end

function show_header(h::Header)
    d = h.mandatory_attributes
    for key in [
           :IAEA_INDEX,
           :TITLE,
           :FILE_TYPE,
           :CHECKSUM,
        ]
        if haskey(d, key)
            val = d[key]
            show_kv(io,key,val)
            println(io)
        end
    end
    show_record_contents(io, h.record_contents)
end

function extra_float_count(r::RecordContents{Nf, Ni, Nt}) where {Nf, Ni, Nt}
    Nf
end

function extra_long_count(r::RecordContents{Nf, Ni, Nt}) where {Nf, Ni, Nt}
    Ni
end

function show_record_contents(io::IO, r::RecordContents)
    # $RECORD_CONTENTS:
    # 1     // X is stored ?
    # 1     // Y is stored ?
    # 1     // Z is stored ?
    # 1     // U is stored ?
    # 1     // V is stored ?
    # 1     // W is stored ?
    # 1     // Weight is stored ?
    # 0     // Extra floats stored ?
    # 1     // Extra longs stored ?
    # 0     // Generic integer variable stored in the extralong array [ 0] 

    # $RECORD_CONSTANT:
    # 
    # $RECORD_LENGTH:
    # 33
    t = r.data
    
    show_key(io, "RECORD_CONTENTS")
    record_constants = Float32[]
    for propstr in ["X","Y","Z", "U","V","W", "Weight"]
        field = Symbol(string(propstr))
        if field in propertynames(t)
            val = 0
            push!(record_constants, t.field)
        else
            val = 1
        end
        println(io, val, " "^5, "// ", propstr, " is stored ?")
    end
    Nf = extra_float_count(r)
    Ni = extra_long_count(r)
    println(io, Nf, " "^5, "// Extra floats stored")
    println(io, Ni, " "^5, "// Extra longs stored")
    println(io, "0     // Generic integer variable stored in the extralong array [ 0]")
    println(io)
    
    show_key(io, "RECORD_CONSTANT")
    for c in record_constants
        println(c)
    end
    println(io)
end
