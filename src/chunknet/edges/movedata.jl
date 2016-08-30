# move data
# to-do: support uploading to S3
#include(joinpath(Pkg.dir(), "EMIRT/plugins/aws.jl"))

"""
edge function of movedata
"""
function ef_movedata(c::DictChannel,
                    params::OrderedDict{Symbol, Any},
                    inputs::OrderedDict{Symbol, Any},
                    outputs::OrderedDict{Symbol, Any} )
    # get chunk
    fin = replace(inputs[:prefix], "~", homedir())
    fot = replace(outputs[:dir], "~", homedir())
    for fbase in readdir(dirname(fin))
        if contains(fbase, basename(fin))
            fout = joinpath(fot, fbase)
            mv(joinpath(dirname(fin), fbase),
                joinpath(dirname(fot), fbase), remove_destination=true)
        end
    end
end