#!/usr/bin/env python

import boto3
import zlib
import zipfile
from StringIO import StringIO


def get_lambda_function(script_name='lambda_function.py'):
    with open(script_name, 'r') as myfile:
        data = myfile.read()
    # compress with zip
    data = zlib.compress(data)
    return data


def get_lambda_function_v2(script_name='lambda_function.py'):
    buf = StringIO()
    with zipfile.ZipFile(buf, 'w') as z:
        z.write(script_name)
    buf.seek(0)
    return buf.read()

client = boto3.client('lambda')
client.create_function(
    FunctionName='chunkflow-inference',
    Runtime='python2.7',
    Role='arn:aws:iam::098703261575:role/chunkflow-lambda',
    Handler='lambda_function.lambda_handler',
    Code={
        'ZipFile': get_lambda_function_v2()
    },
    Description='lambda function to launch auto-scale spot fleet.',
    Timeout=3,
    MemorySize=128,
    Publish=True,
    VpcConfig={
        'SubnetIds': [
            'subnet-fb3626a0'
        ],
        'SecurityGroupIds': [
            'sg-84743efb'
        ]
    },
    Tags={
        'User': 'jingpeng',
        'Tool': 'chunkflow'
    }
)
