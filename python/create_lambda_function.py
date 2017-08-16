import boto3

client = boto3.client('lambda')

client.create_function(
    FunctionName='chunkflow-inference',
    Runtime='python2.7',
    Role='chunkflow-lambda',
    Handler='lambda_function.lambda_handler',
    Code={
        'ZipFile': b''
    },
    Description='lambda function to launch auto-scale spot fleet.',
    Timeout=3,
    MemorySize=64,
    Publish=True,
    VpcConfig={
        'SubnetIds':[
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
