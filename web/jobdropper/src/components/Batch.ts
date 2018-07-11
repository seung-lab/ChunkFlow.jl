import AWS = require('aws-sdk');
// import * as AWS from './aws-sdk-2.141.0';

//AWS.config.update({
//    region: process.env.AWS_REGION,
//    credentials: new AWS.Credentials(
//        process.env.AWS_ACCESS_KEY_ID,
//        process.env.AWS_SECRET_ACCESS_KEY )
//});

let batch = new AWS.Batch({
    apiVersion: '2016-08-10',
    region: process.env.AWS_REGION,
    accessKeyId: process.env.AWS_ACCESS_KEY_ID,
    secretAccessKey: process.env.AWS_SECRET_ACCESS_KEY
});

export class AWSBatch {
    private _params = {
        jobDefinition: "CPUInferenceJobDefiniti-4c21ad357cc3025:1",
        jobName: "test",
        jobQueue: "LowPriorityBatchCloudformationJobqueue",
        containerOverrides: {
            command: [
                "julia main.jl -q chunkflow-inference"
            ],
            environment: [
                {
                    name: "User",
                    value: "jingpeng"
                }
            ],
        },
        retryStrategy:{
            attempts: 2
        }
    };

    constructor(jobQueue: string = "LowPriorityBatchCloudformationJobqueue",
                sqsQueue: string = "chunkflow-inference"){
        this._params.containerOverrides.command = ["julia main.jl -q " + sqsQueue];
        this._params.jobQueue = jobQueue;
    }
    submit_job(){
        batch.submitJob(this._params, function(err:any, data:any){
            if (err) console.log(err, err.stack);
            else    console.log(data);
        });
    }
}
