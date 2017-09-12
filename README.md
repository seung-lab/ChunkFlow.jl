ChunkFlow.jl ![ChunkFlow logo](/docs/chunkflow-logo.png?raw=true)
==============
[![Build Status](https://travis-ci.org/seung-lab/ChunkFlow.jl.svg?branch=master)](https://travis-ci.org/seung-lab/ChunkFlow.jl)

# Introduction
the computation was defined as a node. The kinds of node was defined in [a task file](https://github.com/seung-lab/ChunkFlow.jl/blob/master/test/sleep.json)

# Usage

## Find help
    julia main.jl --help
    julia main.jl -h


## Running pipeline using local task configuration json file

    julia main.jl --task=task.json --deviceid=0
    julia main.jl -t task.json -d 0

## Using AWS Simple Queue Service

### Produce a bunch of tasks
- define `task.json` file, the file name can be only a prefix. Task producer will match all the files and produce a bunch of tasks
- produce tasks: `julia taskproducer.jl --task=task.json --awssqs=chunkflow-tasks`

find help:

    julia taskproducer.jl -h

## Fetch tasks from AWS SQS 
launch a number of instances to deal with the tasks. run the same commands in each instance

    julia -j number_of_processes main.jl -n number_of_processes -w wait_seconds_of_each_launch -q queue-name
