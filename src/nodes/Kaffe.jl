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
    @assert isa(chk_img.data, EMImage)
    
    outputLayerName = "output"
    if haskey(nodeConf[:params], :outputLayerName)
        outputLayerName = nodeConf[:params][:outputLayerName]
    end 

    # save as hdf5 file
    fImg        = string(tempname(), ".img.h5")
    fOutPre     = string(tempname(), ".out.")
    fOut        = "$(fOutPre)_dataset1_$(outputLayerName).h5"
    fDataSpec   = string(tempname(), ".spec")
    fForwardCfg = string(tempname(), ".cfg")

    # normalize in 2D section
    if isfile(fImg)
        rm(fImg)
    end
    h5write(fImg, "main", chk_img.data)

    img_origin = Chunks.get_origin( chk_img )
    originOffset = Vector{UInt32}(params[:originOffset])
    outOrigin = [img_origin..., 0x00000001] .+ originOffset

    if !haskey(params, :caffeNetFileMD5)
        params[:caffeNetFileMD5] = ""
    end

    # download trained network
    futureLocalCaffeNetFile     = @spawn download_net(params[:caffeNetFile];
                                        md5 = params[:caffeNetFileMD5])
    futureLocalCaffeModelFile   = @spawn download_net(params[:caffeModelFile])

    if contains(params[:preprocess], "ormaliz")
        preprocess = "dict(type='standardize',mode='2D')"
    elseif contains(params[:preprocess], "rescale")
        preprocess = "dict(type='rescale')"
    elseif contains(params[:preprocess], "divideby")
        preprocess = "dict(type='divideby')"
    else
        error("invalid preprocessing type: $(params[:preprocess])")
    end

    caffeNetFile    = fetch( futureLocalCaffeNetFile )
    caffeModelFile  = fetch( futureLocalCaffeModelFile )

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
    kaffe_root  = $(params[:kaffeDir])
    dspec_path  = $fDataSpec
    model       = $(caffeModelFile)
    weights     = $(caffeNetFile)
    test_range  = [0]
    border      = None
    scan_list   = ['$(outputLayerName)']
    scan_params = $(params[:scanParams])
    save_prefix = $fOutPre
    """
    f = open(fForwardCfg, "w")
    write(f, forwardCfg)
    close(f)
    @show forwardCfg

    # run convnet inference
    if haskey(params, :deviceID) && params[:deviceID]!=nothing
        # this is gpu inference setup
        Base.run(`python2 $(joinpath(params[:kaffeDir],"python/forward.py")) $(params[:deviceID]) $(fForwardCfg) $(params[:batchSize])`)
    else
        # this is cpu inference setup 
        Base.run(`python2 $(joinpath(params[:kaffeDir],"python/forward.py")) $(fForwardCfg)`)
    end 

    # compute cropMarginSize using integer division
    cropMarginSize = params[:cropMarginSize]

    # read output affinity or semantic  map
    f = h5open(fOut)
    # if params[:isCropImg]
    #     out = read(f["main"])
    # else
    sz = size(f["main"])
    out = f["main"][cropMarginSize[1]+1:sz[1]-cropMarginSize[1],
                    cropMarginSize[2]+1:sz[2]-cropMarginSize[2],
                    cropMarginSize[3]+1:sz[3]-cropMarginSize[3], :]
    # end
    close(f)
    # out = read(fOut, Float32, (sz..., 3))
    # perform the cropping
    # out = out[  cropMarginSize[1]+1:sz[1]-cropMarginSize[1],
    #            cropMarginSize[2]+1:sz[2]-cropMarginSize[2],
    #            cropMarginSize[3]+1:sz[3]-cropMarginSize[3], :]


    # reweight affinity to make ensemble
    if haskey(params, :affWeight)
        out .*= eltype(out)(params[:affWeight])
        if haskey(c, inputs[:aff])
            out .+= take!(c, inputs[:aff]).data
        end
    end

    ZERO = convert(eltype(out), 0)
    for i in eachindex(out)
        if isnan(out[i])
            out[i] = ZERO
        end
    end

    chk_out = Chunk(out, outOrigin, chk_img.voxelSize)
    @assert Chunks.get_origin(chk_out)[4] == 1
    
    outputKey = outputs[:aff]
    if !haskey(c, outputKey)
        c[outputKey] = Channel{Chunk}(1)
    end 
    put!(c[outputKey], chk_out)

    # remove temporary files
    rm(fImg);  rm(fOut); rm(fForwardCfg); rm(fDataSpec);
end

"""
    download_net( netFileName::AbstractString )
download
"""
function download_net( fileName::AbstractString; md5::AbstractString = "" )
    # download trained network
    if Clouds.iss3(fileName) || Clouds.isgs(fileName)
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
