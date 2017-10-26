module Sleep

using ..Nodes
export NodeSleep, run  

immutable NodeSleep <: AbstractNode end 

function Nodes.run(x::NodeSleep, c::Dict{String,Channel}, nc::NodeConf)
    t = nc[:params][:time]
    println("sleep for $(t) seconds...")
    sleep(t)
end

end # end of module
