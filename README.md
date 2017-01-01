Please check the [Wiki Page](https://github.com/seung-lab/ChunkFlow.jl/wiki) for more detailed documentation.

## Introduction
the computation was defined as an edge. The kinds of edge was defined in [a task file](https://github.com/seung-lab/ChunkFlow.jl/blob/master/test/test.json)

## Find help
    julia main.jl --help
    julia main.jl -h
## Running pipeline using local task configuration json file

    julia main.jl --task=task.json --gpuid=0
    julia main.jl -t task.json -g 0

## Usage using AWS Simple Queue Service

### produce a bunch of tasks
define `task.json` file, the file name can be only a prefix. Task producer will match all the files and produce a bunch of tasks

produce tasks

    julia taskproducer.jl --task=task.json --awssqs=chunkflow-tasks

find help:

    julia taskproducer.jl -h

### Auto Fetch tasks from AWS SQS "chunkflow-tasks"

    julia main.jl
    julia main.jl -g 0
the `0` is a device ID.
