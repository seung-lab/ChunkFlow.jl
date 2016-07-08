include("edge.jl")
using EMIRT
using HDF5
using DataStructures

export EdgeZNNi, forward!

type EdgeZNNi <: AbstractEdge
    kind::Symbol
    params::Dict{Symbol, Any}
    # the inputs and outputs are all nodes, which are in kvstore
    inputs::Vector{Symbol}
    outputs::Vector{Symbol}
end

function EdgeZNNi(conf::OrderedDict{UTF8String, Any})
    kind = Symbol(conf["kind"])
    @assert kind == :znni
    params = Dict{Symbol, Any}()
    for (k,v) in conf["params"]
        params[Symbol(k)] = v
    end
    inputs = [Symbol(conf["inputs"][1])]
    @assert length(conf["inputs"]) == 1
    outputs = [Symbol(conf["outputs"][1]), Symbol(conf["outputs"][2])]
    @assert length(conf["outputs"]) == 2

    EdgeZNNi(kind, params, inputs, outputs)
end

function forward!( c::DictChannel, e::EdgeZNNi)
    println("-----------start znni------------")
    chk_img = fetch(c, e.inputs[1])
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
    cd(dirname(fznni))
    run(`$(fznni) $(fimg) $(faff) main`)
    cd(currentdir)

    # read affinity map
    aff = readaff(faff)
    chk_aff = Chunk(aff, chk_img.origin, chk_img.voxelsize)
    # crop img and aff
    cropsize = (e.params[:fov]-1)./2
    chk_img = crop_border(chk_img, cropsize)
    chk_aff = crop_border(chk_aff, cropsize)

    put!(c, e.outputs[1], chk_img)
    put!(c, e.outputs[2], chk_aff)
    println("-------znni end-------")
end
