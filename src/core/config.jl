using DataStructures
using JSON

typealias TCfg OrderedDict{Symbol, Any}

function save(fname, cfg)
    f = open(fname, "w")
    write(f, JSON.json(cfg))
    close(f)
end
