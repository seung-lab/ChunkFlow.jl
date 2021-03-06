module Kaffe
using ..Edges 
using HDF5
using BigArrays
using EMIRT
using OffsetArrays

using ChunkFlow.Utils.Clouds

export EdgeKaffe, run 
struct EdgeKaffe <: AbstractComputeEdge end 

"""
edge function of kaffe forward pass

{
    "params": {
        "outputLayerName": "output",
        "outputStartOffset": (0,0,0,0),
        "cropMarginSize": (64,64,4),
        "deviceID": 0,
        "outputLayerName": "output",
        "caffeModelFile": "/tmp/cores2",
        "preprocess": "divideby"
    },
    "inputs":{
        "img": "img"
    },
    "outputs": {
        "out": "aff" 
    }
}
"""
function Edges.run(x::EdgeKaffe, c::Dict{String, Channel},
                   edgeConf::EdgeConf)
    params = edgeConf[:params]
    inputs = edgeConf[:inputs]
    outputs = edgeConf[:outputs]
    # note that the fetch only use reference rather than copy
    # anychange for chk_img could affect the img in dickchannel
    chk_img = take!(c[inputs[:img]])

    outputLayerName = "output"
    if haskey(params, :outputLayerName)
        outputLayerName = params[:outputLayerName]
    end 
    

    img_start = indices( chk_img )
    outputStartOffset = Vector{UInt32}(params[:outputStartOffset])
    outOrigin = [img_start[1:3]...] .+ outputStartOffset[1:3]

    # compute cropMarginSize using integer division
    cropMarginSize = params[:cropMarginSize]
    
    local out::Array 
    if haskey(params, :deviceID) && params[:deviceID] >= 0
        # gpu inference
        out = kaffe(chk_img |> parent, params[:caffeModelFile]; 
                scanParams = params[:scanParams], preprocess = params[:preprocess], 
                caffeNetFile = params[:caffeNetFile], caffeNetFileMD5 = params[:caffeNetFileMD5], 
                deviceID=params[:deviceID], batchSize=params[:batchSize],
                outputLayerName=outputLayerName)
    else
        # cpu inference
        out = kaffe(chk_img |> parent, params[:caffeModelFile]; 
                scanParams = params[:scanParams], 
                preprocess = params[:preprocess],
                batchSize=params[:batchSize],
                outputLayerName=outputLayerName)
    end 
    # crop margin
    sz = size(out)
    cropMarginSize = params[:cropMarginSize]
    out = out[cropMarginSize[1]+1:sz[1]-cropMarginSize[1],
              cropMarginSize[2]+1:sz[2]-cropMarginSize[2],
              cropMarginSize[3]+1:sz[3]-cropMarginSize[3], :]
    # if only one channel, change to 3D array
    if size(out, 4) == 1
        out = squeeze(out, 4)
    end 
    chk_out = Chunk(out, outOrigin, chk_img.voxelSize)
    
    outputKey = outputs[:chunk]
    if !haskey(c, outputKey)
        c[outputKey] = Channel{Chunk}(1)
    end 
    put!(c[outputKey], chk_out)
end 

function kaffe( img::Array{UInt8, 3}, caffeModelFile::AbstractString; 
               scanParams::AbstractString = "dict(stride=(0.8,0.8,0.8),blend='bump')",
               preprocess::AbstractString="dict(type='divideby')", 
               caffeNetFile::AbstractString="", 
               caffeNetFileMD5::AbstractString="",
               deviceID::Int = 0, batchSize::Int = 1, 
               outputLayerName::AbstractString = "output")
    # save as hdf5 file
    fImg        = string(tempname(), ".img.h5")
    fOutPre     = string(tempname(), ".out.")
    fOut        = "$(fOutPre)_dataset1_$(outputLayerName).h5"
    fDataSpec   = string(tempname(), ".spec")
    fForwardCfg = string(tempname(), ".cfg")

    h5write(fImg, "main", img)

    # download trained network
    caffeNetFile     = download_net(caffeNetFile; md5 = caffeNetFileMD5)
    caffeModelFile   = download_net(caffeModelFile)

    @assert startswith(scanParams, "dict(")

#    caffeNetFile    = fetch( futureLocalCaffeNetFile )
#    caffeModelFile  = fetch( futureLocalCaffeModelFile )

    # data specification file
    dataspec = """
    [files]
    img = $fImg

    [image]
    file = img
    preprocess = $(preprocess)

    [dataset]
    input = image
    """
    f = open(fDataSpec, "w")
    write(f, dataspec)
    close(f)

    forwardCfg = """
    [forward]
    kaffe_root  = /opt/kaffe
    dspec_path  = $fDataSpec
    model       = $(caffeModelFile)
    weights     = $(caffeNetFile)
    test_range  = [0]
    border      = None
    scan_list   = ['$(outputLayerName)']
    scan_params = $(scanParams)
    save_prefix = $fOutPre
    """
    f = open(fForwardCfg, "w")
    write(f, forwardCfg)
    close(f)
    @show forwardCfg

    # run convnet inference
    if deviceID >= 0
        # this is gpu inference setup
        Base.run(`python2 /opt/kaffe/python/forward.py $(deviceID) $(fForwardCfg) $(batchSize)`)
    else
        # this is cpu inference setup 
        Base.run(`python2 /opt/kaffe/python/forward.py $(fForwardCfg)`)
    end 

    # read output affinity or semantic  map
    out = h5read(fOut, "main")
    # remove temporary files
    rm(fImg);  rm(fOut); rm(fForwardCfg); rm(fDataSpec);
    return out
end

"""
    download_net( netFileName::AbstractString )
download
"""
function download_net( fileName::AbstractString; md5::AbstractString = "" )
    # download trained network
    if isempty(fileName)
        return ""
    elseif Clouds.iss3(fileName) || Clouds.isgs(fileName)
        localFileName = replace(fileName, "gs://", "/tmp/")
        localFileName = replace(localFileName, "s3://", "/tmp/")
        localFileName = strip(localFileName, '/')
        localFileName = "/tmp/$(basename(localFileName))"
        @show localFileName
        if !(isfile(localFileName) && is_md5_correct(localFileName, md5))
            # sleep for some time in case some other process is downloading
            #sleep(rand(1:100))
            if !(isfile(localFileName) && is_md5_correct(localFileName, md5))
                Clouds.download(fileName, localFileName)
                @assert is_md5_correct(localFileName, md5)
            end
        end
    else
        localFileName = expanduser( fileName )
    end
    @assert (isdir(localFileName) || isfile(localFileName)) "caffe file not found: $(localFileName)"
    return localFileName
end


function is_md5_correct(fileName::String, md5::String)
    if md5 == ""
        return true
    else
        str = readstring(`md5sum $fileName`)
        # @show fileName
        # @show split(str, " ")[1]
        # @show md5
        return split(str, " ")[1] == md5
    end
end

end # end of module
