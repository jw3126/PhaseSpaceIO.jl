@deprecate open_phsp(args...;kw...) phsp_iterator(args...;kw...)
@deprecate marginals(args...;kw...) histmap(args...;kw...)
@deprecate spectrum(particles;kw...) marginals(p->p.E, particles;kw...)
