using ArgParse

function parse_commandline()
    s = ArgParseSettings()
    @add_arg_table s begin
        "--capacity", "-c"
            help = "target capacity of spot fleet"
            arg_type = Int
            default = 1
        "--imagetag", "-t"
            help = "docker image tag"
            arg_type = String
            default = "v1.4.5"
        "--workernumber", "-w"
            help = "number of workers/processes"
            default = 1
            arg_type = Int
        "--queuename", "-q"
            help = "AWS SQS queue name"
            arg_type = String
            default = "pinky-inference"
    end
    return parse_args(s)
end

const argDict = parse_commandline()
@show argDict

function get_request_string(;
                            targetCapacity  = argDict["capacity"],
                            dockerImageTag  = argDict["imagetag"],
                            workerNumber    = argDict["workernumber"],
                            queueName       = argDict["queuename"])
    user_data_string = """
#!/bin/bash
#apt-get update && apt-get install -y nfs-common
#mkfs -t ext4 /dev/xvdba
#mount /dev/xvdba /tmp
eval "\$(aws ecr get-login)"
nvidia-docker run --net=host -i 098703261575.dkr.ecr.us-east-1.amazonaws.com/chunkflow:$(dockerImageTag) bash -c 'source /root/.bashrc  && export PYTHONPATH=\$PYTHONPATH:/opt/caffe/python && export PYTHONPATH=\$PYTHONPATH:/opt/kaffe/layers && export PYTHONPATH=\$PYTHONPATH:/opt/kaffe && export LD_LIBRARY_PATH=\${LD_LIBRARY_PATH}:/opt/caffe/build/lib && julia -O3 --check-bounds=no --math-mode=fast -p $(workerNumber) ~/.julia/v0.5/ChunkFlow/scripts/main.jl -w $(workerNumber) -a $(queueName)'
"""
    user_data_base64_code = base64encode( user_data_string )


    request_string = """
{
   "IamFleetRole":"arn:aws:iam::098703261575:role/aws-ec2-spot-fleet-role",
   "AllocationStrategy":"lowestPrice",
   "TargetCapacity":1,
   "SpotPrice":"0.9",
   "ValidFrom":"2017-04-06T12:36:06Z",
   "ValidUntil":"2018-04-06T12:36:06Z",
   "TerminateInstancesWithExpiration":true,
   "LaunchSpecifications":[
      {
         "ImageId":"ami-06ae2e10",
         "InstanceType":"p2.xlarge",
         "KeyName":"jpwu_workstation",
         "SpotPrice":"0.9",
         "IamInstanceProfile":{
            "Arn":"arn:aws:iam::098703261575:instance-profile/pipeline"
         },
         "BlockDeviceMappings":[
            {
               "DeviceName":"/dev/sda1",
               "Ebs":{
                  "DeleteOnTermination":true,
                  "VolumeType":"gp2",
                  "VolumeSize":70,
                  "SnapshotId":"snap-c9043e4d"
               }
            }
         ],
         "SecurityGroups":[
            {
               "GroupId":"sg-4cc3cc34"
            }
         ],
         "UserData":"$user_data_base64_code"
      }
   ]
}
"""
# removed
   # "Type":"maintain"

    request_string = replace(request_string, "\n", "")
    request_string = replace(request_string, " ",  "")
    return request_string
end

request_string = get_request_string()

# save file
write("/tmp/config.json", request_string)

@show request_string
# run(`aws ec2 help`)
run(`/Users/jpwu/anaconda/bin/aws ec2 request-spot-fleet --spot-fleet-request-config file:///tmp/config.json`)