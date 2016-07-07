include("edge.jl")
using EMIRT

export EdgeOmni, forward!

type EdgeOmni <: AbstractEdge
    kind::Symbol
    params::Dict{Symbol, Any}
    # the inputs and outputs are all nodes, which are in kvstore
    inputs::Vector{Symbol}
end

function EdgeOmni(conf::OrderedDict{UTF8String, Any})
    kind = Symbol(conf["kind"])
    @assert kind == :omnification
    params = Dict{Symbol, Any}()
    for (k,v) in conf["params"]
        params[Symbol(k)] = v
    end
    inputs = [Symbol(conf["inputs"][1]), Symbol(conf["inputs"][2])]
    @assert length(conf["inputs"]) == 2
    @assert length(conf["outputs"]) == 0

    EdgeOmni(kind, params, inputs)
end

function forward!( c::DictChannel, e::EdgeOmni)
    chk_img = fetch(c, e.inputs[1])
    chk_sgm = fetch(c, e.inputs[2])
    img = chk_img.data
    sgm = chk_sgm.data
    @assert isimg(img)
    @assert issgm(sgm)

    fimg = "/tmp/img.h5"
    fsgm = "/tmp/sgm.h5"
    fcmd = "/tmp/omnify.cmd"
    saveimg(fimg, img, "main")
    savesgm(fsgm, sgm)
    # compute physical offset
    phyOffset = physical_offset(chk_img)
    # voxel size
    vs = chk_img.voxelsize

    # prepare the cmd file for omnification
    # make omnify command file
    cmd = """create:$(e.params[:fprj])
    loadHDF5chann:$(fimg)
    setChanResolution:1,$(vs[1]),$(vs[2]),$(vs[3])
    setChanAbsOffset:,1,$(phyOffset[1]),$(phyOffset[2]),$(phyOffset[3])
    loadHDF5seg:$(fsgm)
    setSegResolution:1,$(vs[1]),$(vs[2]),$(vs[3])
    setSegAbsOffset:1,$(phyOffset[1]),$(phyOffset[2]),$(phyOffset[3])
    mesh
    quit
    """
    # write the cmd file
    f = open(fcmd, "w")
    write(f, cmd)
    close(f)

    # run omnifycation
    run(`$(e.params[:ombin]) --headless --cmdfile=$(fcmd))`)
end
