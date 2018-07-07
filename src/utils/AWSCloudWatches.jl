module AWSCloudWatches
using JSON
using AWSCore 
import AWSSDK.CloudWatch 

function __init__()
    if haskey(ENV, "AWS_ACCESS_KEY_ID") 
        #AWSCore.set_debug_level(2)
        global const AWS_CREDENTIAL = AWSCore.aws_config()
    elseif isfile("/secrets/aws-secret.json")
            d = JSON.parsefile("/secrets/aws-secret.json")
            global const AWS_CREDENTIAL = AWSCore.aws_config(creds=AWSCredentials(d["AWS_ACCESS_KEY_ID"], d["AWS_SECRET_ACCESS_KEY"]))
    else 
            warn("did not find AWS credential! set it in environment variables.")
    end 
end 

function record_elapsed(edge_name, elapsed; namespace="ChunkFlow/")
    CloudWatch.put_metric_data(AWS_CREDENTIAL;
                               Namespace=namespace,                
			MetricData=[["MetricName"   => "time_elapsed",       
						 "Timestamp"    => now(),              
						 "Value"        => elapsed,            
						 "Unit"         => "Seconds",          
						 "Dimensions"   => [[                  
							"Name"      => "edge",             
							"Value"     => "$edge_name"             
						]]                                     
			]])                                                
end 

mutable struct Timer
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

function get_total_elapsed(t::Timer)
    return time() - t.start 
end 

function get_elapsed!(t::Timer)
    elapsed = time() - t.prev 
    t.prev = time()
    return elapsed 
end

end # end of module
