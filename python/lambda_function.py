#!/usr/bin/env python

import boto3
import base64
from datetime import datetime


def get_user_data():
    # my bash code to execute
    user_data = """#!/bin/bash
apt-get update && apt-get install -y nfs-common
mkfs -t ext4 /dev/xvdca
mount /dev/xvdca /tmp
eval "$(aws ecr get-login --no-include-email)"
nvidia-docker run --net=host -i 098703261575.dkr.ecr.us-east-1.amazonaws.com/chunkflow:v1.9.1 bash -c 'source /root/.bashrc  && export PYTHONPATH=$PYTHONPATH:/opt/caffe/python:/opt/kaffe/layers:/opt/kaffe && export LD_LIBRARY_PATH=${LD_LIBRARY_PATH}:/opt/caffe/build/lib && julia -O3 --check-bounds=no --math-mode=fast -p 2 ~/.julia/v0.5/ChunkFlow/scripts/main.jl -n 2 -w 2 -q chunkflow-inference'
"""
    return user_data


def lambda_handler(event, context):
    print('received event: %s' % event)
    # launch a node to handle this task
    ec2 = boto3.client('ec2')
    ec2.request_spot_fleet(
        DryRun=False,
        SpotFleetRequestConfig={
            'AllocationStrategy': 'diversified',
            'IamFleetRole': 'aws-ec2-spot-fleet-role',
            'LaunchSpecifications': [
                {
                    'SecurityGroups': [
                        {
                            'GroupName': 'chunkflow',
                            'GroupId': 'sg-d5f2b1ab'
                        },
                    ],
                    'BlockDeviceMappings': [
                        {
                            'DeviceName': '/dev/sdb',
                            'VirtualName': 'ephemeral0'
                        },
                        {
                            'DeviceName': '/dev/sdc',
                            'VirtualName': 'ephemeral1'
                        }
                    ],
                    'EbsOptimized': False,
                    'ImageId': 'ami-b94c77c2',
                    'InstanceType': 'p2.xlarge',
                    'Monitoring': {
                        'Enabled': False
                    },
                    'NetworkInterfaces': [
                        {
                            'AssociatePublicIpAddress': True,
                            'DeleteOnTermination': True,
                            'Description': 'chunkflow spot fleet for convnet inference'
                        }
                    ],
                    'UserData': base64.b64encode(get_user_data()),
                    'WeightedCapacity': 1,
                    'TagSpecifications': [
                        {
                            'ResourceType': 'instance',
                            'Tags': [
                                {
                                    'Key': 'User',
                                    'Value': 'jingpeng'
                                },
                                {
                                    'Key': 'Tool',
                                    'Value': 'chunkflow'
                                },
                                {
                                    'Key': 'Project',
                                    'Value': 's1'
                                },
                            ]
                        },
                    ]
                },
            ],
            'SpotPrice': '0.9',
            'TargetCapacity': 1,
            'Type': 'maintain',
            'TerminateInstancesWithExpiration': True,
            'ValidFrom': datetime(2017, 8, 16),
            'ValidUntil': datetime(2018, 10, 16),
            'ReplaceUnhealthyInstances': True
        }
    )
