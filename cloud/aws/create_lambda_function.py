#!/usr/bin/env python

import boto3
import zipfile
from StringIO import StringIO


def get_lambda_function(script_name='lambda_function.py'):
    buf = StringIO()
    with zipfile.ZipFile(buf, 'w') as z:
        z.write(script_name)
    buf.seek(0)
    return buf.read()

client = boto3.client('lambda')

# delete the function
# client.delete_function(FunctionName='chunkflow-inference')
#
# response = client.create_function(
#     FunctionName='chunkflow-inference',
#     Runtime='python2.7',
#     Role='arn:aws:iam::098703261575:role/chunkflow-lambda',
#     Handler='lambda_function.lambda_handler',
#     Code={
#         'ZipFile': get_lambda_function()
#     },
#     Description='lambda function to launch auto-scale spot fleet.',
#     Timeout=10,
#     MemorySize=128,
#     Publish=True,
#     VpcConfig={
#         'SubnetIds': [
#             'subnet-fb3626a0'
#         ],
#         'SecurityGroupIds': [
#             'sg-84743efb'
#         ]
#     },
#     Tags={
#         'User': 'jingpeng',
#         'Tool': 'chunkflow'
#     }
# )

response = client.update_function_code(
    FunctionName='chunkflow-inference',
    ZipFile=get_lambda_function(),
    Publish=True,
    DryRun=False
)

print('response = %s' % response)
