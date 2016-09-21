# save chunk from dictchannel to local disk or aws s3
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
    voxelSize = chk
    if haskey(outputs, :chunkFileName)
        chunkFileName = outputs[:chunkFileName]
        @assert contains(chunkFileName, ".h5")
    else
        prefix = replace(outputs[:prefix],"~",homedir())
        chksz = size(chk)
        chunkFileName = "$(prefix)$(chk.origin[1])-$(chk.origin[1]+chksz[1]-1)_$(chk.origin[2])-$(chk.origin[2]+chksz[2]-1)_$(chk.origin[3])-$(chk.origin[3]+chksz[3]-1).$(inputs[:chunk]).h5"
    end
    if iss3(chunkFileName)
        ftmp = string(tempname(), ".chk.h5")
        BigArrays.save(ftmp, chk)
        run(`aws s3 mv $ftmp $chunkFileName`)
    else
        BigArrays.save(chunkFileName, chk)
    end

end
