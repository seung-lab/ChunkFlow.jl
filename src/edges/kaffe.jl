using HDF5
using BigArrays

"""
edge function of kaffe forward pass
"""
function ef_kaffe!( c::DictChannel,
                params::OrderedDict{Symbol, Any},
                inputs::OrderedDict{Symbol, Any},
                outputs::OrderedDict{Symbol, Any})
    # note that the fetch only use reference rather than copy
    # anychange for chk_img could affect the img in dickchannel
    chk_img = fetch(c, inputs[:img])
    @assert isa(chk_img.data, EMImage)

    # save as hdf5 file
    fImg        = string(tempname(), ".img.h5")
    fAffPre     = string(tempname(), ".aff.")
    fAff        = "$(fAffPre)_dataset1_output.h5"
    fDataSpec   = string(tempname(), ".spec")
    fForwardCfg = string(tempname(), ".cfg")

    # normalize in 2D section
    if isfile(fImg)
        rm(fImg)
    end
    h5write(fImg, "main", chk_img.data)

    @show chk_img.origin
    @show params[:originOffset]
    originOffset = Vector{UInt32}(params[:originOffset])
    affOrigin = [chk_img.origin..., 0x00000001] .+ originOffset

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
    @show dataspec

    forwardCfg = """
    [forward]
    kaffe_root  = $(params[:kaffeDir])
    dspec_path  = $fDataSpec
    model       = $(caffeModelFile)
    weights     = $(caffeNetFile)
    test_range  = [0]
    border      = None
    scan_list   = ['output']
    scan_params = $(params[:scanParams])
    save_prefix = $fAffPre
    """
    f = open(fForwardCfg, "w")
    write(f, forwardCfg)
    close(f)
    @show forwardCfg

    # log the chunk coordinate for debug
    # info("processing chunk origin from: $(chk_img2.origin) with a size of $(size(chk_img2.data))")

    # run znni inference
    run(`python2 $(joinpath(params[:kaffeDir],"python/forward_bin.py")) $(params[:deviceID]) $(fForwardCfg)`)

    # compute cropMarginSize using integer division
    sz = size(chk_img.data)
    cropMarginSize = params[:cropMarginSize]

    # read affinity map
    # f = h5open(fAff)
    # if params[:isCropImg]
    #   aff = read(f["main"])
    # else
    #   aff = f["main"][cropMarginSize[1]+1:sz[1]-cropMarginSize[1],
    #                   cropMarginSize[2]+1:sz[2]-cropMarginSize[2],
    #                   cropMarginSize[3]+1:sz[3]-cropMarginSize[3], :]
    # end
    # close(f)
    aff = read(fAff, Float32, sz)
    # perform the cropping
    aff = aff[  cropMarginSize[1]+1:sz[1]-cropMarginSize[1],
                cropMarginSize[2]+1:sz[2]-cropMarginSize[2],
                cropMarginSize[3]+1:sz[3]-cropMarginSize[3], :]


    # reweight affinity to make ensemble
    aff .*= eltype(aff)(params[:affWeight])
    if isready(c, inputs[:aff])
      aff .+= take!(c, inputs[:aff]).data
    end

    ZERO = convert(eltype(aff), 0)
    for i in eachindex(aff)
        if isnan(aff[i])
            aff[i] = ZERO
        end
    end

    chk_aff = Chunk(aff, affOrigin, chk_img.voxelSize)
    @assert chk_aff.origin[4] == 1

    # crop img and aff
    put!(c, outputs[:aff], chk_aff)

    # remove temporary files
    rm(fImg);  rm(fAff); rm(fForwardCfg); rm(fDataSpec);
end

"""
    download_net( netFileName::AbstractString )
download
"""
function download_net( fileName::AbstractString; md5::AbstractString = "" )
    # download trained network
    if iss3(fileName) || isgs(fileName)
        localFileName = replace(fileName, "gs://", "/tmp/")
        localFileName = replace(localFileName, "s3://", "/tmp/")
        @show localFileName
        if !(isfile(localFileName) && is_md5_correct(localFileName, md5))
            # sleep for some time in case some other process is downloading
            sleep(rand(1:100))
            if !(isfile(localFileName) && is_md5_correct(localFileName, md5))
                download(fileName, localFileName)
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
