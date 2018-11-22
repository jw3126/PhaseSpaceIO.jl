module TestIAEA
using Test
using PhaseSpaceIO

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

end #module
