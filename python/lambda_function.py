import boto3
import base64

def lambda_handler(event, context):
    # my bash code to execute
    myscript="""#!/bin/bash
#apt-get update && apt-get install -y nfs-common
#mkfs -t ext4 /dev/xvdca
#mount /dev/xvdca /tmp
eval "$(aws ecr get-login)"
nvidia-docker run --net=host -i 098703261575.dkr.ecr.us-east-1.amazonaws.com/chunkflow:v1.8.1 bash -c 'source /root/.bashrc  && export PYTHONPATH=$PYTHONPATH:/opt/caffe/python && export PYTHONPATH=$PYTHONPATH:/opt/kaffe/layers && export PYTHONPATH=$PYTHONPATH:/opt/kaffe && export LD_LIBRARY_PATH=${LD_LIBRARY_PATH}:/opt/caffe/build/lib && julia -O3 --check-bounds=no --math-mode=fast -p 2 ~/.julia/v0.5/ChunkFlow/scripts/main.jl -w 2 -q chunkflow-inference'
""".format(bucket, key)
    # launch a node to handle this task
    ec2 = boto3.client('ec2')
    ami = 'ami-692dd504'
    if "spot" in key:
        ec2.request_spot_instances(
            DryRun = False,
            SpotPrice = '2.7',
            InstanceCount = 1,
            Type = 'one-time',
            LaunchSpecification = {
                'ImageId': ami,
                'KeyName': 'jpwu_workstation',
                'InstanceType': 'r3.8xlarge',
                'UserData': base64.b64encode(myscript),
                'BlockDeviceMappings':[
                    {
                        'VirtualName': 'ephemeral0',
                        'DeviceName': '/dev/sdb'
                    },
                    {
                        'VirtualName': 'ephemeral1',
                        'DeviceName': '/dev/sdc'
                    }
                ]
            }
        )
    else:
        ec2.run_instances(
            DryRun = False,
            ImageId = ami,
            MinCount = 1 ,
            MaxCount = 1 ,
            KeyName = 'jpwu_workstation',
            UserData = myscript,
            InstanceType = 'r3.8xlarge',
            InstanceInitiatedShutdownBehavior='terminate',
            BlockDeviceMappings = [
                {
                    'VirtualName': 'ephemeral0',
                    'DeviceName': '/dev/sdb'
                },
                {
                    'VirtualName': 'ephemeral1',
                    'DeviceName': '/dev/sdc'
                }
            ]
        )

