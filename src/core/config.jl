using DataStructures
using JSON

typealias TCfg OrderedDict{Symbol, Any}

"""
transfer config to string
"""
function cfg2str( cfg::TCfg )
    # convert to string
    ftmp = tempname()
    f = open(ftmp, "w")
    JSON.print(f, cfg)
    close(f)
    readall(ftmp)
end

function save(fname, cfg)
    f = open(fname, "w")
    write(f, cfg2str(cfg))
    close(f)
end
