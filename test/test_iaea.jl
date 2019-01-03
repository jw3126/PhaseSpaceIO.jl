module TestIAEA
using Test
using PhaseSpaceIO
using PhaseSpaceIO.Testing

@testset "IAEA save load with many consants" begin
    r = RecordContents{0,0}(x=1, y=2, z=3, u=0, v=1, weight=5)
    p_truth = IAEAParticle(x=1,y=2,z=3,u=0,v=1,w=0,weight=5, typ=photon, E=6)
    path = IAEAPath(tempname())
    iaea_writer(path, r) do w
        write(w, p_truth)
    end
    
    r_reloaded, ps_reloaded = phsp_iterator(path) do iter
        iter.header, collect(iter)
    end
    @test r_reloaded == r
    @test length(ps_reloaded) == 1
    @test first(ps_reloaded) == p_truth
    rm(path)
end

@testset "finalizer" begin
    function write_sloppy(path, ps, r)
        w = iaea_writer(path, r)
        for p in ps
            write(w, p)
        end
    end
    path = IAEAPath(tempname())
    ps = [arbitrary(IAEAParticle{0,1})]
    r = RecordContents{0,1}()
    write_sloppy(path, ps, r)
    GC.gc()
    ps2 = phsp_iterator(collect, path)
    @test length(ps) == length(ps2) == 1
    @test first(ps) ≈ first(ps2)
    rm(path)
end

end #module
