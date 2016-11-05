using Escher
using Reactive

import Escher:  Sampler

function submit_tasks(d::Dict)
    @show d
    if !isempty(d)
        d[:stride]   = map(parse, split(d[:stride],   ","))
        d[:gridSize] = map(parse, split(d[:gridSize], ","))
        d[:origin]   = map(parse, split(d[:origin],   ","))
    end
    return string(d)
end

function main(window)
    push!(window.assets, "widgets")

    inp = Signal(Dict())

    s = Escher.sampler()
    form = vbox(
        h1("Submit Your Jobs"),
        watch!(s, :computeGraph, textinput("", label="Computation Graph", multiline=true)),
        watch!(s, :origin, textinput("1,1,1", label="origin", multiline=false)),
        watch!(s, :stride, textinput("1024,1024,128", label="stride", multiline=false)),
        watch!(s, :gridSize, textinput("1,1,1", label="Chunk Grid Size", multiline=false)),
        watch!(s, :queueName, textinput("chunkflow-tasks", label="AWS SQS Queue Name", multiline=false)),
        trigger!(s, :submit, button("Submit"))
    ) |> maxwidth(400px)

    map(inp) do dict
        vbox(
            intent(s, form) >>> inp,
            vskip(2em),
            # string(dict)
            submit_tasks(dict)
        ) |> Escher.pad(2em)
    end
end
