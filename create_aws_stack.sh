#!/bin/bash 

aws cloudformation create-stack --stack-name chunkflow --template-body file://template.drosophila.yml --capabilities CAPABILITY_IAM
