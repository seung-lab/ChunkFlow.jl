using HDF5
using BigArrays
using DataStructures

"""
edge function of saveh5
"""
function ef_saveh5!(c::DictChannel,
                    params::OrderedDict{Symbol, Any},
                    inputs::OrderedDict{Symbol, Any},
                    outputs::OrderedDict{Symbol, Any} )
    chk = fetch(c, inputs[:chunk])
    origin = get_origin(chk)
    data = get_data(chk)
    tmpFileName = tempname()
    f = h5open(tmpFileName, "w")
    if contains(params[:compression], "deflate")
        f[params[:datasetName], "shuffle",(), "deflate", 3] = data
    elseif contains(params[:compression], "blosc")
        f[params[:datasetName], "blosc", 5] = data
    else
        error("unsupported compression: $(params[:compression])")
    end
    close(f)

    fileName = params[:fileNamePrefix]
    for i in ndims(data)
        fileName = "$fileName_$o-$(origin[i]+size(data)[i]-1)"
    end
    fileName = "$fileName.h5"
    @show fileName

    if ismatch(r"s3://", fileName)
        run(`aws s3 mv $tmpFileName $fileName`)
    elseif ismatch(r"^gs://", fileName)
        run(`gsutil mv $tmpFileName $fileName`)
    else
        mv(tmpFileName, fileName)
    end
end
