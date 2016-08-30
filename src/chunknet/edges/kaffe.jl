using HDF5

"""
edge function of kaffe forward pass
"""
function ef_kaffe!( c::DictChannel,
                params::OrderedDict{Symbol, Any},
                inputs::OrderedDict{Symbol, Any},
                outputs::OrderedDict{Symbol, Any})
    chk_img = fetch(c, inputs[:img])
    @assert isa(chk_img.data, Timg)

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
    @show fImg

    # data specification file
    dataspec = """
    [files]
    img = $fImg

    [image]
    file = img
    preprocess = dict(type='standardize',mode='2D')

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
    model       = $(params[:fModel])
    weights     = $(params[:fNet])
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

    # run znni inference
    # currentdir = pwd()
    # cd(joinpath(params[:kaffeDir],"/python"))
    run(`python $(joinpath(params[:kaffeDir],"python/forward.py")) $(params[:GPUID]) $(fForwardCfg)`)
    # cd(currentdir)

    # compute cropMarginSize using integer division
    sz = size(chk_img.data)
    cropMarginSize = params[:affCropMarginSize]

    # read affinity map
    f = h5open(fAff)
    aff = f["main"][cropMarginSize[1]+1:sz[1]-cropMarginSize[1],
                    cropMarginSize[2]+1:sz[2]-cropMarginSize[2],
                    cropMarginSize[3]+1:sz[3]-cropMarginSize[3],:]
    close(f)

    # reweight affinity to make ensemble
    aff .*= eltype(aff)(params[:affWeight])
    if isready(c, inputs[:aff])
      aff .+= take!(c, inputs[:aff]).data
    end

    chk_aff = Chunk(aff, chk_img.origin, chk_img.voxelsize)
    # crop img and aff
    put!(c, outputs[:aff], chk_aff)

    # remove temporary files
    rm(fImg);  rm(fAff); rm(fForwardCfg); rm(fDataSpec);
end
