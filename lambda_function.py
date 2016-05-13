import boto3

def lambda_handler(event, context):
    s3 = boto3.client('s3')
    # find the triger file in bucket
    record = event['Records'][0]
    bucket = record['s3']['bucket']['name']
    key = record['s3']['object']['key']

    # my bash code to execute
    myscript="""#!/bin/bash
export HOME=/root/
export JULIA_LOAD_PATH=$JULIA_LOAD_PATH:/usr/local/share/julia/site/v0.4/Agglomerator/src
export JULIA_LOAD_PATH=$JULIA_LOAD_PATH:/usr/local/share/julia/site/v0.4/Agglomerator/deps/datasets
export JULIA_LOAD_PATH=$JULIA_LOAD_PATH:/usr/local/share/julia/site/v0.4/Agglomerator/deps/
export JULIA_LOAD_PATH=$JULIA_LOAD_PATH:/usr/local/share/julia/site/v0.4/Agglomerator/deps/watershed/src-julia
export JULIA_LOAD_PATH=$JULIA_LOAD_PATH:/usr/local/share/julia/site/v0.4/Agglomerator/src/InputOutput
export JULIA_LOAD_PATH=$JULIA_LOAD_PATH:/usr/local/share/julia/site/v0.4/Agglomerator/src/Features
export JULIA_LOAD_PATH=$JULIA_LOAD_PATH:/usr/local/share/julia/site/v0.4/Agglomerator/src/Visualization
export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/opt/boost/lib

cd /opt/spipe
git checkout master
git pull

cd /usr/local/share/julia/v0.4/EMIRT
git checkout master
git pull

mkfs -t ext4 /dev/xvde
mount /dev/xvde /tmp
rm -rf /tmp/*

julia /opt/spipe/main.jl s3://{}/{}
""".format(bucket, key)

    # launch a node to handle this task
    ec2 = boto3.client('ec2')
    ec2.run_instances(
        DryRun = False,
        ImageId = 'ami-75698918',
        MinCount = 1 ,
        MaxCount = 1 ,
        KeyName = 'jpwu_workstation',
        UserData = myscript,
        InstanceType = 'r3.8xlarge',
        InstanceInitiatedShutdownBehavior='terminate', # 'stop' | 'terminate',
        BlockDeviceMappings = [
            {
                'VirtualName': 'ephemeral0',
                'DeviceName': '/dev/sde',
                'Ebs':{
                    'VolumeSize': 1000,
                    'DeleteOnTermination': True,
                    'VolumeType': 'standard',
                    'Encrypted': False
                }
            }
        ]
    )
