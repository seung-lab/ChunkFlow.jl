#!/usr/bin/env python

import boto3
#from lambda_function import get_user_data

client = boto3.client('autoscaling')

# response = client.create_launch_configuration(
#    LaunchConfigurationName='chunkflow-inference',
#    ImageId='ami-d0fe54c6',
#    KeyName='jingpeng',
#    SecurityGroups=[
#        'sg-84743efb'
#    ],
#    UserData= get_user_data(),
#    InstanceType='p2.xlarge',
#    InstanceMonitoring={
#        'Enabled': True
#    },
#    SpotPrice='0.91',
#    EbsOptimized=False,
#    AssociatePublicIpAddress=True
#    #PlacementTenancy='dedicated'
#)
#print('response of create launch configuration: %s' % response)

response = client.create_auto_scaling_group(
    AutoScalingGroupName='chunkflow-inference',
    LaunchConfigurationName='chunkflow-inference',
    MinSize=0,
    MaxSize=400,
    DesiredCapacity=0,
    DefaultCooldown=60, # default is 300
    AvailabilityZones=[
        'us-east-1a',
        'us-east-1b',
        'us-east-1c',
        'us-east-1d',
        'us-east-1e',
        'us-east-1f'
    ],
    HealthCheckType='EC2',
    VPCZoneIdentifier='subnet-063e7b5c,subnet-c58a4aa1,subnet-f92062d5,subnet-e44e48ac,subnet-bf729380,subnet-5627665a'
)

print('response of creating auto scaling group: %s' % response)
