using DataStructures
using JSON

typealias TCfg OrderedDict{Symbol, Any}

function save(fileName, cfg)
    f = open(fileName, "w")
    write(f, JSON.json(cfg))
    close(f)
end
