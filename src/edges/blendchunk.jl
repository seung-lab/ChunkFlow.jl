# save chunk from dictchannel to BigArrays

using BigArrays
using DataStructures

"""
edge function of blendchunk
"""
function ef_blendchunk(c::DictChannel,
                    params::OrderedDict{Symbol, Any},
                    inputs::OrderedDict{Symbol, Any},
                    outputs::OrderedDict{Symbol, Any} )
    # get chunk
    chk = fetch(c, inputs[:chunk])

    ba = BigArray(outputs[:BigArrayDir])
    blendchunk(ba, chk)
end
