
mutable struct GeneratedAttributes
    length::Int64
    counts::Dict{ParticleType, Int64}
    energy_min::Dict{ParticleType, Float32}
    energy_max::Dict{ParticleType, Float32}
    energy_sum::Dict{ParticleType, Float64}
    x_min::Float32
    x_max::Float32
    y_min::Float32
    y_max::Float32
    z_min::Float32
    z_max::Float32
end

function GeneratedAttributes()
    GeneratedAttributes(0,
        Dict(),
        Dict(),
        Dict(),
        Dict(),
        Inf, -Inf,
        Inf, -Inf,
        Inf, -Inf
    )
end

struct PhaseSpaceWriter{R, I <: IO}
    record_contents::R
    generated_attributes::GeneratedAttributes
    io_header::I
    io_phsp::I
end

function increment(d, key, val=1)
    T = eltype(values(d))
    d[key] = get!(d,key,zero(T)) + val
end

function Base.write(io::PhaseSpaceWriter, p::Particle)
    ret = write_particle(io.io_phsp, p, io.record_contents)
    
    ga = io.generated_attributes
    typ = p.particle_type
    increment(ga.counts, typ, 1)
    ga.length += 1
    increment(ga.energy_sum, typ, p.E * p.weight)
    ga.energy_min[typ] = min(get!(ga.energy_min, typ, Inf), p.E)
    ga.energy_max[typ] = max(get!(ga.energy_max, typ, -Inf), p.E)
    
    ga.x_min = min(ga.x_min, p.x)
    ga.y_min = min(ga.y_min, p.y)
    ga.z_min = min(ga.z_min, p.z)
    ga.x_max = max(ga.x_max, p.x)
    ga.y_max = max(ga.y_max, p.y)
    ga.z_max = max(ga.z_max, p.z)
    
    ret
end

function show_key(io::IO, k)
    println(io,'$',k,":")
end
function show_val(io, v)
    if v != ""
        println(io,v)
    end
end
function showln_kv(io::IO, k, v)
    show_key(io,k)
    show_val(io,v)
    println(io)
end

function show_header(io::IO, w::PhaseSpaceWriter)
    showln_kv(io, :IAEA_INDEX, "0 // test header")
    showln_kv(io, :TITLE, "")
    showln_kv(io, :FILE_TYPE, 0)
    r = w.record_contents
    ga = w.generated_attributes
    record_length = compressed_particle_sizeof(r)
    checksum = ga.length * record_length
    showln_kv(io, :CHECKSUM, checksum)
    show_record_contents(io, r)
    showln_kv(io, :RECORD_LENGTH, record_length)
    showln_kv(io, :BYTE_ORDER, "1234")
    showln_kv(io, :ORIG_HISTORIES, "18446744073709551615")
    showln_kv(io, :PARTICLES, ga.length)
    # $PHOTONS:
    # 1
    # 
    # $TRANSPORT_PARAMETERS:
    # 
    # $MACHINE_TYPE:
    # 
    # $MONTE_CARLO_CODE_VERSION:
    # 
    # $GLOBAL_PHOTON_ENERGY_CUTOFF:
    #   0.00000 
    # $GLOBAL_PARTICLE_ENERGY_CUTOFF:
    #   0.00000 
    # $COORDINATE_SYSTEM_DESCRIPTION:
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

function phsp_writer(path::IAEAPath, r::RecordContents)
    io_header = open(path.header, "w") 
    io_phsp   = open(path.phsp  , "w")
    ga = GeneratedAttributes()
    writer = PhaseSpaceWriter(r, ga, io_header, io_phsp)
end
phsp_writer(path) = phsp_writer(IAEAPath(path))

function Base.close(w::PhaseSpaceWriter)
    show_header(w.io_header, w)
    close(w.io_header)
    close(w.io_phsp)
end

function phsp_writer(f, path, r::RecordContents)
    w = phsp_writer(IAEAPath(path), r)
    ret = f(w)
    close(w)
    ret
end
