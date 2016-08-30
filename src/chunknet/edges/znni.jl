using EMIRT
using HDF5
using DataStructures

#include(joinpath(Pkg.dir(), "EMIRT/plugins/aws.jl"))

"""
edge function of znni
"""
function ef_znni!( c::DictChannel,
                params::OrderedDict{Symbol, Any},
                inputs::OrderedDict{Symbol, Any},
                outputs::OrderedDict{Symbol, Any})
    chk_img = fetch(c, inputs[:img])
    img = chk_img.data
    @assert isa(img, Timg)

    # save as hdf5 file
    fimg = "/tmp/img.h5"
    faff = "/tmp/aff.h5"

    # normalize in 2D section
    imgnor = normalize(img)
    if isfile(fimg)
        rm(fimg)
    end
    h5write(fimg, "main", imgnor)

    # prepare parameters
    currentdir = pwd()
    fznni = replace(params[:fznni], "~", homedir())
    outsz = params[:outsz]

    # checke the existance of binary network file
    fnetbin = joinpath(dirname(fznni), "VD2D3D-MS")
    if !isdir(fnetbin)
        fnet = replace(params[:fnet], "~", homedir())
        if contains(fnet, "s3://")
            fnet = download(env, fnet, "/tmp/net.h5")
        end
        fnet2bin = joinpath(dirname(fznni), "../../../julia/net2bin.jl")
        run(`julia $(fnet2bin) $(fnet) $(fnetbin)`)
    end

    # run znni inference
    cd(dirname(fznni))
    run(`$(fznni) $(fimg) $(faff) main $(outsz[3]) $(outsz[2]) $(outsz[1])`)
    cd(currentdir)

    # compute cropsize using integer division
    sz = size(chk_img.data)
    cropsize = div(params[:fov]-1, 2)

    # crop image
    chk_img = crop_border!(chk_img, cropsize)
    put!(c, outputs[:img], chk_img)

    # read affinity map
    f = h5open(faff)
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
    gc()
end
