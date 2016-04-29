## Running pipeline locally
running the whole pipeline:
`julia main.jl params.cfg`

## Running pipeline in AWS
we provide running pipeline as a service. If you would like to run the pipeline from registered image stack to omni projects, you can just upload a task config file to AWS S3. Hopefully, after a while (depends on the network and dataset size), you'll find you omni project in S3.

# pipeline with 1 stage ZNN forward pass
- upload your raw image and ZNN network to S3
- upload a task file to S3 task folder: 
`https://console.aws.amazon.com/s3/home?region=us-east-1#&bucket=spipe-service&prefix=tasks-1-stage/`
this will trigger an event to launch an instance to process your data. After finishing, it will transfer your result to the `outdir` in S3. Then, terminate itself to release resources.

example of task configuration:
`https://github.com/seung-lab/spipe/blob/aws/params_aws.cfg`

# pipeline with 2 stage ZNN forward pass

- upload your raw image and ZNN network to S3
- upload a task file to S3 task folder: 
`https://console.aws.amazon.com/s3/home?region=us-east-1#&bucket=spipe-service&prefix=tasks-2-stage/`
this will trigger an event to launch an instance to process your data. After finishing, it will transfer your result to the `outdir` in S3. Then, terminate itself to release resources.

example of task configuration:
`https://github.com/seung-lab/spipe/blob/aws/params_aws.cfg`

find your result in the directory of `outdir` in configuration file.

