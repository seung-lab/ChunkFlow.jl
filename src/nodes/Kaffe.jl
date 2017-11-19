module Kaffe
using ..Nodes 
using HDF5
using BigArrays
using BigArrays.Chunks
using EMIRT
include("../utils/Clouds.jl"); using .Clouds

export NodeKaffe, run 
struct NodeKaffe <: AbstractComputeNode end 

"""
node function of kaffe forward pass
"""
function Nodes.run(x::NodeKaffe, c::Dict{String, Channel},
                   nodeConf::NodeConf)
    params = nodeConf[:params]
    inputs = nodeConf[:inputs]
    outputs = nodeConf[:outputs]
    # note that the fetch only use reference rather than copy
    # anychange for chk_img could affect the img in dickchannel
    chk_img = take!(c[inputs[:img]])

    outputLayerName = "output"
    if haskey(nodeConf[:params], :outputLayerName)
        outputLayerName = nodeConf[:params][:outputLayerName]
    end 
    

    img_origin = Chunks.get_origin( chk_img )
    originOffset = Vector{UInt32}(params[:originOffset])
    outOrigin = [img_origin[1:3]...] .+ originOffset[1:3]

    # compute cropMarginSize using integer division
    cropMarginSize = params[:cropMarginSize]
    
    local out::Array 
    if haskey(params, :deviceID) && params[:deviceID] >= 0
        # gpu inference
        out = kaffe(chk_img.data, 
                params[:scanParams], params[:preprocess]; 
                caffeModelFile = params[:caffeModelFile], 
                caffeNetFile = params[:caffeNetFile], caffeNetFileMD5 = params[:caffeNetFileMD5], 
                deviceID=params[:deviceID], batchSize=params[:batchSize],
                outputLayerName=params[:outputLayerName])
    else
        # gpu inference
        out = kaffe(chk_img.data, 
                params[:scanParams], params[:preprocess]; 
                deviceID=params[:deviceID], batchSize=params[:batchSize],
                outputLayerName=params[:outputLayerName])
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
    
    outputKey = outputs[:aff]
    if !haskey(c, outputKey)
        c[outputKey] = Channel{Chunk}(1)
    end 
    put!(c[outputKey], chk_out)
end 

function kaffe( img::AbstractArray, 
                scanParams::AbstractString, preprocess::AbstractString; 
                caffeModelFile::AbstractString="", 
                caffeNetFile::AbstractString="", caffeNetFileMD5::AbstractString="",
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

    if contains(preprocess, "ormaliz")
        preprocess = "dict(type='standardize',mode='2D')"
    elseif contains(preprocess, "rescale")
        preprocess = "dict(type='rescale')"
    elseif contains(preprocess, "divideby")
        preprocess = "dict(type='divideby')"
    else
        error("invalid preprocessing type: $(params[:preprocess])")
    end

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
        @show localFileName
        if !(isfile(localFileName) && is_md5_correct(localFileName, md5))
            # sleep for some time in case some other process is downloading
            sleep(rand(1:100))
            if !(isfile(localFileName) && is_md5_correct(localFileName, md5))
                Clouds.download(fileName, localFileName)
                @assert is_md5_correct(localFileName, md5)
            end
        end
    else
        localFileName = expanduser( fileName )
    end
    @assert isfile(localFileName) "caffe file not found: $(localFileName)"
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
