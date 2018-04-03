ChunkFlow.jl ![ChunkFlow logo](/docs/chunkflow-logo.png?raw=true)
==============
[![Build Status](https://travis-ci.org/seung-lab/ChunkFlow.jl.svg?branch=master)](https://travis-ci.org/seung-lab/ChunkFlow.jl)

# Introduction
ChunkFlow was used to run convnet inference for large scale 3D image volume across clouds and local cluster. The job scheduling is based on AWS SQS, and all the jobs was produced and ingested to a queue in AWS SQS. Then, we can launch workers anywhere with internet connection and AWS authentication to fetch jobs from the queue. After finishing the job, worker will delete the job in queue and fetch another one to work on until all the jobs were done.

# Usage
all the scripts are in the `scripts` directory.

## produce test tasks of golden cube
```
julia produce_starts.jl -q chunkflow-inference -o -25,-25,-8 -s 1024,1024,128 -g 2,2,2
```

## ConvNet Inference

```
julia inference.jl -q chunkflow-inference -i s3://neuroglancer/pinkygolden_v0/image/4_4_40 -y s3://neuroglancer/pinkygolden_v0/affinitymap-rs-unet-cremi/4_4_40 -v /import/rs-unet-cremi-4cores -d -1 -s 1024,1024,128
```
