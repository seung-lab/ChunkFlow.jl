using HDF5

"""
edge function of kaffe forward pass
"""
function ef_kaffe!( c::DictChannel,
                params::OrderedDict{Symbol, Any},
                inputs::OrderedDict{Symbol, Any},
                outputs::OrderedDict{Symbol, Any})
    chk_img = fetch(c, inputs[:img])
    img = chk_img.data
    @assert isa(img, Timg)

    # save as hdf5 file
    fImg        = string(tempname(), ".img.h5")
    fAffPre     = string(tempname(), ".aff.")
    fAff        = "$(fAffPre)0.h5"
    fDataSpec   = string(tempname(), ".spec")
    fForwardCfg = string(tempname(), ".cfg")

    # normalize in 2D section
    imgNor = normalize(img)
    if isfile(fImg)
        rm(fImg)
    end
    h5write(fImg, "main", imgNor)

    # data specification file
    dataspec = """
    [files]
    img = $fImg

    [image]
    file = img
    preprocess = {}

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

    # run znni inference
    currentdir = pwd()
    cd(joinpath(params[:kaffeDir],"/python"))
    run(`python forward.py $(params[:gpuID]) $(fForwardCfg)`)
    cd(currentdir)

    # compute cropsize using integer division
    sz = size(chk_img.data)
    cropsize = params[:affCropSize]

    # read affinity map
    f = h5open(fAff)
    if params[:isexchangeaffxz]
        aff = zeros(Float32, (  sz[1]-cropsize[1]*2,
                                sz[2]-cropsize[2]*2,
                                sz[3]-cropsize[3]*2,3))
        aff[:,:,:,1] = f["main"][   cropsize[1]+1:sz[1]-cropsize[1],
                                    cropsize[2]+1:sz[2]-cropsize[2],
                                    cropsize[3]+1:sz[3]-cropsize[3],3]
        aff[:,:,:,2] = f["main"][   cropsize[1]+1:sz[1]-cropsize[1],
                                    cropsize[2]+1:sz[2]-cropsize[2],
                                    cropsize[3]+1:sz[3]-cropsize[3],2]
        aff[:,:,:,3] = f["main"][   cropsize[1]+1:sz[1]-cropsize[1],
                                    cropsize[2]+1:sz[2]-cropsize[2],
                                    cropsize[3]+1:sz[3]-cropsize[3],1]
    else
        aff = f["main"][cropsize[1]+1:sz[1]-cropsize[1],
                        cropsize[2]+1:sz[2]-cropsize[2],
                        cropsize[3]+1:sz[3]-cropsize[3],:]
    end
    close(f)
    chk_aff = Chunk(aff, chk_img.origin, chk_img.voxelsize)
    # crop img and aff
    put!(c, outputs[:aff], chk_aff)

    # remove temporary files
    rm(fImg);  rm(fAff); rm(fForwardCfg); rm(fDataSpec);
    # collect garbage to release memory explicitly
    gc()
end
