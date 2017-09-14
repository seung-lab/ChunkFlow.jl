module Watch

import AWSSDK.CloudWatch 

function record_elapsed(node_name, elapsed; namespace="ChunkFlow/")
    CloudWatch.put_metric_data(;Namespace=namespace,                
			MetricData=[["MetricName"   => "time_elapsed",       
						 "Timestamp"    => now(),              
						 "Value"        => elapsed,            
						 "Unit"         => "Seconds",          
						 "Dimensions"   => [[                  
							"Name"      => "node",             
							"Value"     => "$node_name"             
						]]                                     
			]])                                                
end 

type Timer
    start   :: Float64
    prev    :: Float64 
end

# constructor
function Timer()
    Timer(time(), time()) 
end

function start!(t::Timer)
    t.start = time()
end 

function get_elapsed!(t::Timer)
    elapsed = time() - t.prev 
    t.prev = time()
    return elapsed 
end

end # end of module
