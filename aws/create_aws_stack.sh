#!/bin/bash 

aws cloudformation create-stack --stack-name chunkflow --template-body file://template.yml --capabilities CAPABILITY_IAM
