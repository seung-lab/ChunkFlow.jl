# Introduction

we are going to ingest an aligned dataset to cloud storage with neuroglancer format. The dataset should be visualizable directly with neuroglancer.

# preparation


## Install packages
- julia v0.5
- ChunkFlow.jl
- BigArrays.jl
- GSDicts.jl for Google cloud storage
- S3Dicts.jl  for AWS S3 storage

## task description file
the ingestion was split to a bunch of tasks. Each task do a cutout from aligned sections, and rewrite to cloud storage as a gzip compressed binary file.

here is an example of ingestion configuration file:
```json
{"input": {
    "kind": "cutoutchunk",
    "params":{
        "bigArrayType": "aligned",
        "origin":   [1, 1, 1],
        "cutoutSize": [4096, 4096,  64],
        "offset":    [0,0,0],
        "voxelSize": [4,4,40],
        "nonzeroRatioThreshold": 0.01
    },
    "inputs": {
      "registerFile": "/mnt/data01/datasets/pinky40-4/5_finished/registry.txt"
    },
    "outputs": {
        "data": "img"
    }
},
"blend2cloud":{
    "kind": "blendchunk",
    "params":{
      "backend": "gs"
    },
    "inputs": {
        "chunk": "img"
    },
    "outputs": {
        "path": "gs://neuroglancer/pinky40_v4/image/4_4_40/"
    }
}
}
```
save as a text json file. let's say `ingest2gs.json`

## submit tasks to AWS SQS

checkout the usage of `taskproducer.jl` by `julia taskproducer.jl -h`
here is an example of producing tasks, modify the parameters accordingly.

    cd ~/.julia/v0.5/ChunkFlow/scripts/
    julia taskproducer.jl -t ingest2gs.json -a pinky-ingest2cloud -o -16383,-4095,1 -s 2048,2048,64 -g 50,44,16


# execute tasks

execute the tasks in the worker nodes. For ingestion, we normally do it manually in a few instances, which have the dataset downloaded. We planned to have batch ingestion in the future. 

checkout the usage of `mail.jl` in `ChunkFlow/scripts/`:

    julia mail.jl -h

here is an example of launching 6 ingestion processes.

    julia -p 6 --check-bounds=no main.jl -w 1 -q pinky-ingest2cloud -n 6

have a cup of tea and wait for the instance doing the task! You can check the progress by looking at the SQS queue in the AWS web-console


