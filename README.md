## Find help
    julia main.jl --help
    julia main.jl -h
## Running pipeline using local task configuration json file
the computation was defined in a graph.

    julia main.jl --task=task.json --gpuid=0
    julia main.jl -t task.json -g 0

## Auto Fetch tasks from AWS SQS "chunkflow-tasks"
    julia main.jl 

the computation was defined as an edge. The kinds of edge was defined in [a task file](https://github.com/seung-lab/ChunkFlow.jl/blob/master/test/test.json)
