import Escher:  Sampler

include(joinpath(Pkg.dir(),"EMIRT/src/plugins/emshow.jl"))
include("plotcurve.jl")
include("segmentation.jl")
include("evaluate.jl")

main(window) = begin
    push!(window.assets, "layout2")
    push!(window.assets, "icons")
    push!(window.assets, "widgets")

    tabbar = tabs([hbox(icon("autorenew"),     hskip(1em), "Train"),
                   hbox(icon("trending-down"), hskip(1em), "LearningCurve"),
                   hbox(icon("forward"),       hskip(1em), "Inference"),
                   hbox(icon("dashboard"),     hskip(1em), "Segmentation"),
                   hbox(icon("assessment"),    hskip(1em), "Evaluate"),
                   hbox(icon("polymer"),       hskip(1em), "Pipeline"),
                   hbox(icon("help"),          hskip(1em), "Help")] )
    tabcontents = pages([ "training"; plotcurve(); "inference"; segmentation(); evaluate(); "Pipeline"; "help"])

    t, p = wire( tabbar, tabcontents, :tabschannel, :selected)

    vbox(toolbar(["Reconstruction as a Service @", iconbutton("cloud"), flex()]),
         Escher.pad(1em, t),
         Escher.pad(1em, p))
end