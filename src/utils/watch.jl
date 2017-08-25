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

end
