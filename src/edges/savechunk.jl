# save chunk from dictchannel to local disk or aws s3

include(joinpath(Pkg.dir(), "EMIRT/plugins/cloud.jl"))
using BigArrays
using DataStructures

"""
edge function of readh5
"""
function ef_savechunk(c::DictChannel,
                    params::OrderedDict{Symbol, Any},
                    inputs::OrderedDict{Symbol, Any},
                    outputs::OrderedDict{Symbol, Any} )
    # get chunk
    chk = fetch(c, inputs[:chunk])
    origin = chk.origin
    voxelsize = chk
    if haskey(outputs, :fname)
        fname = outputs[:fname]
        @assert contains(fname, ".h5")
    else
        prefix = replace(outputs[:prefix],"~",homedir())
        fname = "$(prefix)$(chk.origin[1])_$(chk.origin[2])_$(chk.origin[3]).$(inputs[:chunk]).h5"
    end
    if iss3(fname)
        ftmp = string(tempname(), ".chk.h5")
        save(ftmp, chk)
        run(`aws s3 mv $ftmp $fname`)
    else
        BigArrays.save(fname, chk)
    end

end
