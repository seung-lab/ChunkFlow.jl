module Sleep

import ..Nodes.AbstractNode 
import ..Nodes.NodeConf 

export NodeSleep, run  

immutable NodeSleep <: AbstractNode end 

function run(x::NodeSleep, c::Dict, nc::NodeConf)
    t = nc[:params][:time]
    println("sleep for $(t) seconds...")
    sleep(t)
end

end # end of module
