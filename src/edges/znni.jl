using HDF5
using DataStructures

"""
edge function of znni
"""
function nf_znni!( c::DictChannel,
                params::OrderedDict{Symbol, Any},
                inputs::OrderedDict{Symbol, Any},
                outputs::OrderedDict{Symbol, Any})
    chk_img = fetch(c, inputs[:img])
    @assert isa(chk_img.data, EMImage)

    # save as hdf5 file
    fimg = string(tempname(), ".img.h5")
    faff = string(tempname(), ".aff.h5")

    # normalize in 2D section
    imgnor = EMIRT.normalize(chk_img.data)
    if isfile(fimg)
        rm(fimg)
    end
    h5write(fimg, "main", imgnor)
    # release memory
    imgnor = nothing; gc()

    # prepare parameters
    currentdir = pwd()
    znniBinaryFile = replace(params[:znniBinaryFile], "~", homedir())
    outputPatchSize = params[:outputPatchSize]

    # checke the existance of binary network file
    fnetbin = joinpath(dirname(znniBinaryFile), "VD2D3D-MS")
    if !isdir(fnetbin)
        fnet = replace(params[:fnet], "~", homedir())
        if contains(fnet, "s3://")
            fnet = download(fnet, "/tmp/net.h5")
        end
        fnet2bin = joinpath(dirname(znniBinaryFile), "../../../julia/net2bin.jl")
        run(`julia $(fnet2bin) $(fnet) $(fnetbin)`)
    end

    # run znni inference
    cd(dirname(znniBinaryFile))
    run(`$(znniBinaryFile) $(params[:deviceID]) $(fimg) $(faff) main $(outputPatchSize[3]) $(outputPatchSize[2]) $(outputPatchSize[1])`)
    cd(currentdir)

    # compute cropMarginSize using integer division
    sz = size(chk_img.data)
    cropMarginSize = div(params[:fieldOfView]-1, 2)

    # read affinity map
    f = h5open(faff)
    if params[:isExchangeAffXZ]
        aff = zeros(Float32, (  sz[1]-cropMarginSize[1]*2,
                                sz[2]-cropMarginSize[2]*2,
                                sz[3]-cropMarginSize[3]*2,3))
        aff[:,:,:,1] = f["main"][   cropMarginSize[1]+1:sz[1]-cropMarginSize[1],
                                    cropMarginSize[2]+1:sz[2]-cropMarginSize[2],
                                    cropMarginSize[3]+1:sz[3]-cropMarginSize[3],3]
        aff[:,:,:,2] = f["main"][   cropMarginSize[1]+1:sz[1]-cropMarginSize[1],
                                    cropMarginSize[2]+1:sz[2]-cropMarginSize[2],
                                    cropMarginSize[3]+1:sz[3]-cropMarginSize[3],2]
        aff[:,:,:,3] = f["main"][   cropMarginSize[1]+1:sz[1]-cropMarginSize[1],
                                    cropMarginSize[2]+1:sz[2]-cropMarginSize[2],
                                    cropMarginSize[3]+1:sz[3]-cropMarginSize[3],1]
    else
        aff = f["main"][cropMarginSize[1]+1:sz[1]-cropMarginSize[1],
                        cropMarginSize[2]+1:sz[2]-cropMarginSize[2],
                        cropMarginSize[3]+1:sz[3]-cropMarginSize[3],:]
    end
    close(f)

    @show aff[1:100]

    # reweight affinity to make ensemble
    if params[:affWeight] != 1
      aff .*= eltype(aff)(params[:affWeight])
    end
    if isready(c, inputs[:aff])
      aff .+= take!(c, inputs[:aff]).data
    end

    chk_aff = Chunk(aff, [chk_img.origin...,0x00000001].+
                    Vector{typeof(chk_img.origin)}(cropMarginSize),
                    chk_img.voxelSize)
    # crop img and aff
    put!(c, outputs[:aff], chk_aff)

    # clean files and memory
    rm(faff); rm(fimg)
end
