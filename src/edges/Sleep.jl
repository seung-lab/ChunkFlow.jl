module Sleep

using ..Edges
export EdgeSleep, run  

struct EdgeSleep <: AbstractEdge end 

function Edges.run(x::EdgeSleep, c::Dict{String,Channel}, nc::EdgeConf)
    t = nc[:params][:time]
    println("sleep for $(t) seconds...")
    sleep(t)
end

end # end of module
