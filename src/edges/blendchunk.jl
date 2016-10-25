# save chunk from dictchannel to BigArrays

using BigArrays
using BigArrays.H5sBigArrays
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
    @show size(chk)

    if contains(params[:backend], "h5s")
      ba = H5sBigArray(outputs[:bigArrayDir])
      blendchunk(ba, chk)
    else
      error("unsupported bigarray backend: $(params[:backend])")
    end
end
