#!/usr/bin/env python

import boto3
# from .lambda_function import get_user_data

client = boto3.client('autoscaling')

# response = client.create_launch_configuration(
#     launchconfigurationname='chunkflow-inference',
#     imageid='ami-d0fe54c6',
#     keyname='jingpeng',
#     securitygroups=[
#         'sg-84743efb'
#     ],
#     userdata= get_user_data(),
#     instancetype='p2.xlarge',
#
# )

response = client.create_auto_scaling_group(
    autoscalinggroupname='chunkflow-inference',
    # launchconfigurationname='chunkflow-inference',
    minsize=0,
    maxsize=400,
    desiredcapacity=0,
    defaultcooldown=30, # default is 300
    availabilityzones=[
        'us-east-1a',
        'us-east-1b',
        'us-east-1c',
        'us-east-1d',
        'us-east-1e'
    ],
    healthchecktype='ec2',

)
