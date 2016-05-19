using Gadfly
using Distributions
using HDF5
#import Escher:  @api, render

# type of learning curve
typealias Tlc Dict{ASCIIString, Dict{ASCIIString,Vector}}

function get_learning_curve(fname::AbstractString)
    if contains(fname, "s3://")
        # local file name
        lcfname = "/tmp/net_current.h5"
        # download from  AWS S3
        run(`aws s3 cp $(fname) $(lcfname)`)
        # rename fname to local file name
        fname = lcfname
    end
    curve = Tlc()
    if isfile(fname)
        curve["train"] = Dict{ASCIIString, Vector}()
        curve["test"]  = Dict{ASCIIString, Vector}()

        curve["train"]["it"]  = h5read(fname, "/processing/znn/train/statistics/train/it")
        curve["train"]["err"] = h5read(fname, "/processing/znn/train/statistics/train/err")
        curve["train"]["cls"] = h5read(fname, "/processing/znn/train/statistics/train/cls")
        curve["test"]["it"]   = h5read(fname, "/processing/znn/train/statistics/test/it")
        curve["test"]["err"]  = h5read(fname, "/processing/znn/train/statistics/test/err")
        curve["test"]["cls"]  = h5read(fname, "/processing/znn/train/statistics/test/cls")
    end
    return curve
end

function tile_learning_curve(curve::Tlc)
    if length( keys(curve) ) == 0
        return ""
    else
        return vbox(
                    md"## Learning Curve of Cost",
                    drawing(8Gadfly.inch, 4Gadfly.inch,
                            plot(layer(x=curve["train"]["it"]/1000, y=curve["train"]["err"],
                                       Geom.line, Theme(default_color=color("blue"))),
                                 layer(x=curve["test"]["it"] /1000, y=curve["test"]["err"],
                                       Geom.line, Theme(default_color=color("red"))),
                                 Guide.xlabel("Iteration (K)"), Guide.ylabel("Cost"))),
        md"## Learning Curve of Pixel Error",
        drawing(8Gadfly.inch, 4Gadfly.inch,
                plot(layer(x=curve["train"]["it"]/1000, y=curve["train"]["cls"],
                           Geom.line, Theme(default_color=color("blue"))),
                     layer(x=curve["test"]["it"] /1000, y=curve["test"]["cls"],
                           Geom.line, Theme(default_color=color("red"))),
                     Guide.xlabel("Iteration (K)"), Guide.ylabel("Pixel Error"))) #,
        ) |> Escher.pad(2em)
    end
end

function tile_learning_curve(fname::AbstractString)
    curve = get_learning_curve(fname)
    return tile_learning_curve(curve)
end

"""
the form tile to provide learning curve plotting tile
"""
function tile_form_network_file!(pcs::Sampler)
    pcform = vbox(
                h1("Choose your network file"),
                watch!(pcs, :fname, textinput("/tmp/net_current.h5", label="network file")),
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
    #pcform = tile_form_network_file!(pcs)
    pcform = vbox(
                  h1("Choose your network file"),
                  watch!(pcs, :fname, textinput("/tmp/net_current.h5", label="network file")),
                  trigger!(pcs, :submit, button("Plot Learning Curve", raised=false))
                  ) |> maxwidth(400px)

    ret = map(pcinp) do pcdict
        vbox(
             intent(pcs, pcform) >>> pcinp,
             vskip(2em),
             tile_learning_curve(get(pcdict, :fname, "")),
             string(pcdict)
             ) |> Escher.pad(2em)
    end
    return ret
end
