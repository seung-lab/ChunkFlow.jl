ChunkFlow.jl ![ChunkFlow logo](/docs/chunkflow-logo.png?raw=true)
==============
[![Build Status](https://travis-ci.org/seung-lab/ChunkFlow.jl.svg?branch=master)](https://travis-ci.org/seung-lab/ChunkFlow.jl)

# Introduction
ChunkFlow was used to run convnet inference for large scale 3D image volume across clouds and local cluster. The job scheduling is based on AWS SQS, and all the jobs was produced and ingested to a queue in AWS SQS. Then, we can launch workers anywhere with internet connection and AWS authentication to fetch jobs from the queue. After finishing the job, worker will delete the job in queue and fetch another one to work on until all the jobs were done.

# Usage
all the scripts are in the `scripts` directory.

## compile pznet with difference number of cores
workstation20 was already configured with intel license and docker image.
[pznet](https://github.com/seung-lab/seunglab-wiki#pznet) 
save the networks in the production docker image from [google registration](https://console.cloud.google.com/gcr/images/neuromancer-seung-import/GLOBAL/jingpeng-znnphi?project=neuromancer-seung-import&gcrImageListsize=50). take tag `pinky40` for example.
build a new docker image with a your own tag, then push it to [Google Cloud Container Registry](https://console.cloud.google.com/gcr/images/neuromancer-seung-import/GLOBAL/jingpeng-znnphi?project=neuromancer-seung-import&gcrImageListsize=50). the command is `gcloud docker -- push gcr.io/neuromancer-seung-import/your-image:your-tag`

## produce test tasks of golden cube
run this in local workstation or docker image to produce a bunch of starting coordinates of `input` chunks.
```
julia produce_starts.jl -q chunkflow-inference -o -25,-25,-8 -s 1024,1024,128 -g 2,2,2
```
Note that the origin should be the starting coordinatge of `input` chunk in the whole dataset. 

use `julia produce_starts.jl -h` to find help information.

## ConvNet Inference in Google Cloud
for the usage of kubernates, please refer to [zfish documentation](https://github.com/seung-lab/zfish_analysis).

### create cluster in google cloud
```
gcloud container --project "neuromancer-seung-import" clusters create "jingpeng-cluster" --zone "us-east1-b" --machine-type "n1-standard-16" --image-type "GCI" --disk-size "100" --scopes "https://www.googleapis.com/auth/compute","https://www.googleapis.com/auth/devstorage.full_control","https://www.googleapis.com/auth/taskqueue","https://www.googleapis.com/auth/logging.write","https://www.googleapis.com/auth/cloud-platform","https://www.googleapis.com/auth/servicecontrol","https://www.googleapis.com/auth/service.management.readonly","https://www.googleapis.com/auth/trace.append" --num-nodes "10" --network "default" --enable-cloud-logging --no-enable-cloud-monitoring
```

### build secret pod for mounting
checkout that the secret files are in /secrets, the format should be the same with [cloud-volume](https://github.com/seung-lab/cloud-volume)
```
kubectl create secret generic secrets \
--from-file=google-secret.json=/secrets/google-secret.json \
--from-file=aws-secret.json=/secrets/aws-secret.json \
--from-file=boss-secret.json=/secrets/boss-secret.json
```

### run the inference containers
an example of `kube_config.yml` file would be like:
```
apiVersion: extensions/v1beta1                                                 
kind: Deployment                                                               
metadata:                                                                      
  name: inference                                                          
  labels:                                                                      
    app: chunkflow                                                             
spec:                                                                          
  replicas: 83                                                                 
  template:                                                                    
    metadata:                                                                  
      labels:                                                                  
        app: neuroglancer                                                      
    spec:                                                                      
      containers:                                                              
        - name: neuroglancer                                                   
          image: gcr.io/neuromancer-seung-import/jingpeng-rs-unet-cremi:64cores
          command: ["bash -c julia inference.jl -q chunkflow-inference -i s3://neuroglancer/pinkygolden_v0/image/4_4_40 -y s3://neuroglancer/pinkygolden_v0/affinitymap-rs-unet-cremi/4_4_40 -v /import/rs-unet-cremi-4cores -d -1 -s 1024,1024,128"]
          env:                                                                 
            - name: AWS_ACCESS_KEY_ID                                          
              value: YOUR_KEY_ID  
            - name: AWS_SECRET_ACCESS_KEY                                      
              value: YOUR_KEY
            - name: AWS_REGION                                                 
              value: us-east-1                                                 
          volumeMounts:                                                        
          - name: secrets                                                      
            mountPath: "/secrets"                                              
            readOnly: true                                                     
          - name: tmp                                                          
            mountPath: "/tmp"                                                  
            readOnly: false                                                    
          imagePullPolicy: Always                                              
          resources:                                                           
            requests:                                                          
                memory: 40Gi                                                   
      volumes:                                                                 
      - name: secrets                                                          
        secret:                                                                
          secretName: secrets                                                  
      - name: tmp                                                              
        emptyDir: { medium: "Memory" }                                         
```
modify it accordingly, and then use `kube create -f kube_config.yml --record` to start the deployment.

## monitoring of progress
there are three ways to monitor the progress.
### AWS SQS
You can keep an eye in the AWS SQS queue.

### kubenates
Goole cloud web console could be used to simply monitor the health of pods. If you need more detailed monitor, you can use `kube proxy -p 8987` to start a local monitor server and then open `localhost:8987` to check the health.

### AWS Watch
There is a ChunkFlow node in AWS Watch, you can monitor the speed of each step.
