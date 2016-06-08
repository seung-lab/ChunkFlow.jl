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

export JULIA_LOAD_PATH=$JULIA_LOAD_PATH:/usr/local/share/julia/site/v0.4/Agglomeration/src
export JULIA_LOAD_PATH=$JULIA_LOAD_PATH:/usr/local/share/julia/site/v0.4/Agglomeration/deps/datasets
export JULIA_LOAD_PATH=$JULIA_LOAD_PATH:/usr/local/share/julia/site/v0.4/Agglomeration/deps/
export JULIA_LOAD_PATH=$JULIA_LOAD_PATH:/usr/local/share/julia/site/v0.4/Agglomeration/deps/watershed/src-julia
export JULIA_LOAD_PATH=$JULIA_LOAD_PATH:/usr/local/share/julia/site/v0.4/Agglomeration/src/InputOutput
export JULIA_LOAD_PATH=$JULIA_LOAD_PATH:/usr/local/share/julia/site/v0.4/Agglomeration/src/Features
export JULIA_LOAD_PATH=$JULIA_LOAD_PATH:/usr/local/share/julia/site/v0.4/Agglomeration/src/Visualization

export JULIA_PKGDIR=/usr/local/share/julia/site/v0.4
export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/opt/boost/lib
export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/usr/lib/libtcmalloc_minimal.so.4

#cd /opt/spipe
#git checkout master
#git pull

cd /opt/znn-release
git checkout master
git pull

#cd /usr/local/share/julia/site/v0.4/EMIRT
#git checkout master
#git pull

#cd /usr/local/share/julia/site/v0.4/Agglomeration
#git checkout master
#git pull

mkfs -t ext4 /dev/xvdb
mount /dev/xvdb /tmp
rm -rf /tmp/*

mkdir /data
mkfs -t ext4 /dev/xvdc
mount /dev/xvdc /data

julia /opt/spipe/src/main.jl s3://{}/{}
#shutdown -h 0
""".format(bucket, key)
    print key
    # launch a node to handle this task
    ec2 = boto3.client('ec2')
    ami = 'ami-8550aee8'
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
