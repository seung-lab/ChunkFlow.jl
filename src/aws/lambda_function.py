import boto3
import base64

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
git pull
git checkout master
git pull

cd /usr/local/share/julia/site/v0.4/EMIRT
git pull
git checkout master
git pull

mkfs -t ext4 /dev/xvdb
mount /dev/xvdb /tmp
rm -rf /tmp/*

mkdir /data
mkfs -t ext4 /dev/xvdc
mount /dev/xvdc /data

julia /opt/spipe/main.jl s3://{}/{}
#shutdown -h 0
""".format(bucket, key)

    # launch a node to handle this task
    ec2 = boto3.client('ec2')
    ec2.request_spot_instances(
        DryRun = False,
        SpotPrice = '2.1',
        InstanceCount = 1,
        Type = 'one-time',
        LaunchSpecification = {
            'ImageId': 'ami-75698918',
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
