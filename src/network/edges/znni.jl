using EMIRT
using HDF5
using DataStructures

export ef_znni!

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

    # run znni inference
    currentdir = pwd()
    fznni = params[:fznni]
    outsz = params[:outsz]
    cd(dirname(fznni))
    run(`$(fznni) $(fimg) $(faff) main $(outsz[3]) $(outsz[2]) $(outsz[1])`)
    cd(currentdir)

    # read affinity map
    aff = readaff(faff)
    chk_aff = Chunk(aff, chk_img.origin, chk_img.voxelsize)
    # crop img and aff
    # compute cropsize using integer division
    cropsize = div(params[:fov]-1, 2)
    chk_img = crop_border!(chk_img, cropsize)
    chk_aff = crop_border!(chk_aff, cropsize)

    put!(c, outputs[:img], chk_img)
    put!(c, outputs[:aff], chk_aff)
end
