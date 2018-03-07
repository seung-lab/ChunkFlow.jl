#!/usr/bin/env python

import time
import boto3
from lambda_function import get_user_data

client = boto3.client('autoscaling')

response = client.delete_auto_scaling_group(
    AutoScalingGroupName='chunkflow-inference',
    ForceDelete=True
)
print('response of deleting auto scaling group: %s' % response)
time.sleep(30)
client.delete_launch_configuration(
    LaunchConfigurationName='chunkflow-inference'
)
time.sleep(10)

response = client.create_launch_configuration(
   LaunchConfigurationName='chunkflow-inference',
   ImageId='ami-b94c77c2',
   KeyName='jingpeng',
   SecurityGroups=[
       'sg-84743efb'
   ],
   UserData= get_user_data(),
   InstanceType='p2.xlarge',
   InstanceMonitoring={
       'Enabled': False
   },
   SpotPrice='0.91',
   IamInstanceProfile='arn:aws:iam::098703261575:instance-profile/chunkflow-worker',
   EbsOptimized=False,
   AssociatePublicIpAddress=True
   #PlacementTenancy='dedicated'
)
print('response of create launch configuration: %s' % response)

response = client.create_auto_scaling_group(
    AutoScalingGroupName='chunkflow-inference',
    LaunchConfigurationName='chunkflow-inference',
    MinSize=0,
    MaxSize=400,
    DesiredCapacity=0,
    DefaultCooldown=300, # default is 300
    AvailabilityZones=[
        'us-east-1a',
        'us-east-1b',
        'us-east-1c',
        'us-east-1d',
        'us-east-1e',
        'us-east-1f'
    ],
    HealthCheckType='EC2',
    VPCZoneIdentifier='subnet-063e7b5c,subnet-c58a4aa1,subnet-f92062d5,subnet-e44e48ac,subnet-bf729380,subnet-5627665a',
    Tags=[
        {
            'ResourceId': 'chunkflow-inference',
            'ResourceType': 'auto-scaling-group',
            'Key': 'User',
            'Value': 'jingpeng',
            'PropagateAtLaunch': True
        },
        {
            'ResourceId': 'chunkflow-inference',
            'ResourceType': 'auto-scaling-group',
            'Key': 'Tool',
            'Value': 'chunkflow',
            'PropagateAtLaunch': True
        }
    ]
)

response = client.update_auto_scaling_group(
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
    VPCZoneIdentifier='subnet-063e7b5c,subnet-c58a4aa1,subnet-f92062d5,subnet-e44e48ac,subnet-bf729380,subnet-5627665a',
)
print('response of creating auto scaling group: %s' % response)

response = client.put_scaling_policy(
    AutoScalingGroupName='chunkflow-inference',
    PolicyName='scale-out',
    PolicyType='StepScaling',
    AdjustmentType='ExactCapacity',
    StepAdjustments=[
        {
            'MetricIntervalLowerBound': 1,
            'MetricIntervalUpperBound': 16,
            'ScalingAdjustment': 1
        },
        {
            'MetricIntervalLowerBound': 16,
            'MetricIntervalUpperBound': 64,
            'ScalingAdjustment': 4
        },
        {
            'MetricIntervalLowerBound': 64,
            'MetricIntervalUpperBound': 256,
            'ScalingAdjustment': 32
        },
        {
            'MetricIntervalLowerBound': 256,
            'MetricIntervalUpperBound': 1024,
            'ScalingAdjustment': 128
        },
        {
            'MetricIntervalLowerBound': 1024,
            'MetricIntervalUpperBound': 4096,
            'ScalingAdjustment': 256
        },
        {
            'MetricIntervalLowerBound': 4096,
            'ScalingAdjustment': 512
        }
    ],
    EstimatedInstanceWarmup=600
)
print('response of put scaling policy: %s' % response)

############ scale in policy ################
# response = client.put_scaling_policy(
#     AutoScalingGroupName='chunkflow-inference',
#     PolicyName='scaling-in',
#     PolicyType='SimpleScaling',
#     AdjustmentType='PercentChangeInCapacity',
#     MinAdjustmentMagnitude=5,
#     ScalingAdjustment=-10
#     Cooldown=600,
# )

response = client.put_scaling_policy(
    AutoScalingGroupName='chunkflow-inference',
    PolicyName='scaling-in',
    PolicyType='TargetTrackingScaling',
    EstimatedInstanceWarmup=600,
    TargetTrackingConfiguration={
        'PredefinedMetricSpecification':{
            'PredefinedMetricType': 'ASGAverageCPUUtilization'
        },
        'TargetValue':5,
        'DisableScaleIn':False
    },
)
