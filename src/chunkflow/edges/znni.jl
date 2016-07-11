using EMIRT
using HDF5
using DataStructures

export ef_znni!

"""
edge function of znni
"""
function ef_znni!( c::DictChannel, e::Edge)
    println("-----------start znni------------")
    chk_img = fetch(c, e.inputs[:img])
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
    fznni = e.params[:fznni]
    outsz = e.params[:outsz]
    cd(dirname(fznni))
    run(`$(fznni) $(fimg) $(faff) main $(outsz[3]) $(outsz[2]) $(outsz[1])`)
    cd(currentdir)

    # read affinity map
    aff = readaff(faff)
    chk_aff = Chunk(aff, chk_img.origin, chk_img.voxelsize)
    # crop img and aff
    cropsize = (e.params[:fov]-1)./2
    chk_img = crop_border!(chk_img, cropsize)
    chk_aff = crop_border!(chk_aff, cropsize)

    put!(c, e.outputs[:img], chk_img)
    put!(c, e.outputs[:aff], chk_aff)
    println("-------znni end-------")
end
