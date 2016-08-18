# save chunk from dictchannel to local disk or aws s3

include(joinpath(Pkg.dir(), "EMIRT/plugins/aws.jl"))
include("../../chunk/chunk.jl")

using DataStructures

export ef_savechk

"""
edge function of readh5
"""
function ef_savechk(c::DictChannel,
                    params::OrderedDict{Symbol, Any},
                    inputs::OrderedDict{Symbol, Any},
                    outputs::OrderedDict{Symbol, Any} )
    # get chunk
    chk = take!(c, inputs[:chunk])
    origin = chk.origin
    voxelsize = chk
    prefix = replace(outputs[:prefix],"~",homedir())
    fname = "$(prefix)$(chk.origin[1])_$(chk.origin[2])_$(chk.origin[3]).$(inputs[:chunk]).h5"
    if iss3(fname)
        ftmp = "/tmp/chk.h5"
        save(ftmp, chk)
        run(`aws s3 mv $ftmp $fname`)
    else
        save(fname, chk)
    end
    # put the input chunk back to channel
    if !params[:isdelete]
        put!(c, inputs[:chunk], chk)
    end
end
