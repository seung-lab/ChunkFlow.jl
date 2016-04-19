import boto3
import json

def lambda_handler(event, context):
    s3 = boto3.client('s3')
    # download the config file from S3 to local lambda server
    fconf = '/tmp/config.cfg'
    for record in event['Records']:
        bucket = record['s3']['bucket']['name']
        key = record['s3']['object']['key'] 
        s3.download_file(bucket, key, fconf)
    
    # read the config file
    f = open(fconf, 'r')
    conf = f.read()
    f.close()
    if conf=="":
        return
    
    # propose the task to aws Simple Queue Service
    sqs = boto3.resource('sqs')
    queue = sqs.get_queue_by_name(QueueName='spipe-tasks')
    # send the configuration file as a message in SQS
    queue.send_message(MessageBody=json.dumps(conf))
    
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
mkfs -t ext4 /dev/xvde                                                                                                 
mount /dev/xvde /tmp
rm -rf /tmp/*
cd /opt/spipe
git pull
#cd /opt/znn-release
#git pull
julia /opt/spipe/main.jl
"""
    
    # launch a master node to handle this task
    ec2 = boto3.client('ec2')
    ec2.run_instances(
        DryRun = False,
        ImageId = 'ami-a6c5d9cc',
        MinCount = 1 ,
        MaxCount = 1 ,
        KeyName = 'jpwu_workstation',
        UserData = myscript,
        InstanceType = 'c4.8xlarge',
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
    
    
