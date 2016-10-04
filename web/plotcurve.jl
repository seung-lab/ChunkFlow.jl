using Gadfly
using Distributions
using HDF5
#import Escher:  @api, render

# type of learning curve
typealias Tlc Dict{String, Dict{String,Vector}}

function get_learning_curve(fileName::AbstractString)
    if contains(fileName, "s3://")
        # local file name
        localFileName = "/tmp/net_current.h5"
        # download from  AWS S3
        run(`aws s3 cp $(fileName) $(localFileName)`)
        # rename fileName to local file name
        fileName = localFileName
    end
    curve = Tlc()
    if isfile(fileName)
        curve["train"] = Dict{String, Vector}()
        curve["test"]  = Dict{String, Vector}()

        curve["train"]["it"]  = h5read(fileName, "/processing/znn/train/statistics/train/it")
        curve["train"]["err"] = h5read(fileName, "/processing/znn/train/statistics/train/err")
        curve["train"]["cls"] = h5read(fileName, "/processing/znn/train/statistics/train/cls")
        curve["test"]["it"]   = h5read(fileName, "/processing/znn/train/statistics/test/it")
        curve["test"]["err"]  = h5read(fileName, "/processing/znn/train/statistics/test/err")
        curve["test"]["cls"]  = h5read(fileName, "/processing/znn/train/statistics/test/cls")
    end
    return curve
end

function tile_learning_curve(curve::Tlc)
    if length( keys(curve) ) == 0
        return ""
    else
        return vbox(
                    md"## Learning Curve of Cost",
                    drawing(6Gadfly.inch, 3Gadfly.inch,
                            plot(layer(x=curve["train"]["it"]/1000, y=curve["train"]["err"],
                                       Theme(default_color=colorant"blue"),
                                       Geom.smooth(method=:loess,smoothing=0.2)),
                                 layer(x=curve["test"]["it"] /1000, y=curve["test"]["err"],
                                       Theme(default_color=colorant"red"),
                                       Geom.smooth(method=:loess,smoothing=0.2)),
                                 Guide.xlabel("Iteration (K)"), Guide.ylabel("Cost"))),
        md"## Learning Curve of Pixel Error",
        drawing(6Gadfly.inch, 3Gadfly.inch,
                plot(layer(x=curve["train"]["it"]/1000, y=curve["train"]["cls"],
                           Theme(default_color=colorant"blue"),
                           Geom.smooth(method=:loess,smoothing=0.2)),
                     layer(x=curve["test"]["it"] /1000, y=curve["test"]["cls"],
                           Theme(default_color=colorant"red" ),
                           Geom.smooth(method=:loess,smoothing=0.2)),
                     Guide.xlabel("Iteration (K)"), Guide.ylabel("Pixel Error")
                     )
                )
        ) |> Escher.pad(2em)
    end
end

function tile_learning_curve(fileName::AbstractString)
    curve = get_learning_curve(fileName)
    return tile_learning_curve(curve)
end

"""
the form tile to provide learning curve plotting tile
"""
function tile_form_network_file!(pcs::Sampler)
    pcform = vbox(
                  h1("Choose your network file"),
                  watch!(pcs, :input1, textinput("/tmp/net_current.h5", label="network file")),
                  watch!(pcs, :input2, textinput("9", label="smooth window size")),
                  trigger!(pcs, :submit, button("Plot Learning Curve", raised=false))
                  ) |> maxwidth(400px)
    return pcform
end

"""
get learning curve plotting tile
`Parameters`:
inp: input
s: sampler

`Return`:
ret: learning curve plotting tile
"""
function plotcurve()
    pcinp = Signal(Dict())
    pcs = Escher.sampler()
    pcform = tile_form_network_file!(pcs)

    ret = map(pcinp) do pcdict
        vbox(
             intent(pcs, pcform) >>> pcinp,
             vskip(2em),
             tile_learning_curve(get(pcdict, :input1, ""))
             #string(pcdict)
             ) |> Escher.pad(2em)
    end
    return ret
end
