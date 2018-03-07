#!/usr/bin/env python

import boto3
client = boto3.client('batch')


def create_compute_environment():
    resp = client.create_compute_environment(
        computeEnvironmentName  = 'convnet-inference',
        type                    = 'MANAGED',
        state                   = 'ENABLED',
        computeResources        = {
            'type'              : 'SPOT',
            'minvCpus'          : 0,
            'maxvCpus'          : 2048,
            'desiredvCpus'      : 0,
            'instanceTypes'     : [ 'p2.xlarge' ],
            'imageId'           : 'ami-b94c77c2',
            'subnets'           : ['subnet-063e7b5c,subnet-c58a4aa1,subnet-f92062d5,subnet-e44e48ac,subnet-bf729380,subnet-5627665a'],
            'securityGroupIds'  : ['sg-6da75110',],
            'ec2KeyPair'        : 'jingpeng',
            'instanceRole'      : 'arn:aws:iam::098703261575:role/chunkflow-worker',
            # spot compute environment do not support tagging!
            'tags'              : {
                'User'          : 'jingpeng',
                'Project'       : 'chunkflow-inference',
                'Tool'          : 'chunkflow'
            },
            'bidPercentage'     : 91,
            'spotIamFleetRole'  : 'arn:aws:iam::098703261575:role/aws-ec2-spot-fleet-role'
        },
        serviceRole             = 'arn:aws:iam::098703261575:role/service-role/AWSBatchServiceRole')
    print('response of create compute environment %s' % resp)
    resp = client.describe_compute_environments()


def register_job_definition(queueName='convnet-inference'):
    resp = client.register_job_definition(
        jobDefinitionName               = 'convnet-inference',
        type                            = 'container',
        parameters                      = {
            'queuename'                 : queueName,
            'workernumber'              : '1',
            'processnumber'             : '1',
            'waittime'                  : '5'
        },
        containerProperties             = {
            'image'                     : '098703261575.dkr.ecr.us-east-1.amazonaws.com/chunkflow:latest',
            'vcpus'                     : 2,
            'memory'                    : 20000,
            'command'                   : [
                "julia",
                "-p", "Ref::processnumber",
                "/root/.julia/v0.5/ChunkFlow/scripts/main.jl",
                "-q", "Ref::queuename",
                "-n", "Ref::workernumber",
                "-w", "Ref::waittime"
            ],
            'jobRoleArn'                : 'arn:aws:iam::098703261575:role/chunkflow-worker',
            'volumes'                   : [
                {
                    'host'              : {
                        'sourcePath'    : '/var/lib/nvidia-docker/volumes/nvidia_driver/latest'
                    },
                    'name'              : 'nvidia'
                }
            ],
            'environment'               : [
                {
                    'name'              : 'PYTHONPATH',
                    'value'             : '$PATHONPATH:/opt/caffe/python'
                },
                {
                    'name'              : 'PYTHONPATH',
                    'value'             : '$PATHONPATH:/opt/kaffe/layers',
                },
                {
                    'name'              : 'PYTHONPATH',
                    'value'             : '$PATHONPATH:/opt/kaffe'
                },
                {
                    'name'              : 'LD_LIBRARY_PATH',
                    'value'             : '${LD_LIBRARY_PATH}:/opt/caffe/build/lib'
                }
            ],
            'mountPoints'               : [
                {
                    "containerPath": "/usr/local/nvidia",
                    "readOnly": False,
                    "sourceVolume": "nvidia"
            	}
            ],
            'privileged'                : False,
            'ulimits'                   : [],
            'user'                      : 'root'
        },
        retryStrategy                   = {
            'attempts'                  : 3
        })
    print('response of register job definition: %s' % resp)

def create_job_queue():
    resp = client.create_job_queue(
        jobQueueName                    = 'convnet-inference',
        state                           = 'ENABLED',
        priority                        = 50,
        computeEnvironmentOrder = [
            {
                'order'                 : 1,
                'computeEnvironment'    : 'convnet-inference'
            }
        ])
    print('response of create job queue: %s' % resp)

def submit_job( jobName     = 'convnet-inference',
                queueName   = 'convnet-inference'):
    resp = client.submit_job(
        jobName         = jobName,
        jobQueue        = 'convnet-inference',
        jobDefinition   = 'convnet-inference',
        parameters      = {
            'queuename'     : queueName,
            'processnumber' : '1',
            'workernumber'  : '1',
            'waittime'      : '5'
        },
        containerOverrides = {
            'command'   : [
                "julia",
                "-p", "Ref::processnumber",
                "/root/.julia/v0.5/ChunkFlow/scripts/main.jl",
                "-q", "Ref::queuename",
                "-n", "Ref::workernumber",
                "-w", "Ref::waittime"
            ],
            'vcpus'     : 2,
            'memory'    : 20000
        },
        retryStrategy   = {'attempts' : 3})
    print('response of submit job: %s' % resp)
    return resp

if __name__ == '__main__':
    import argparse
    parser = argparse.ArgumentParser()
    parser.add_argument("--queuename", "-q",
            default     = 'chunkflow-inference',
            help = "AWS SQS queue name")
    parser.add_argument("--jobname", "-j",
            default = 'convnet-inference',
            help = "name of this job")
    args = parser.parse_args()

    create_compute_environment()
    create_job_queue( )
    register_job_definition( args.queuename )
    submit_job( jobName     = args.jobname,
                queueName   = args.queuename )
    print('job {} submited to queue {}'.format(args.jobname, args.queuename))
