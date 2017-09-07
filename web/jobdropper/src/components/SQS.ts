
import process = require('process');
import AWS = require('aws-sdk');

console.log(process.env);
console.log("aws region: " + process.env.AWS_REGION);
let sqs = new AWS.SQS({
    apiVersion: '2012-11-05',
    region: process.env["AWS_REGION"]
});

const DEFAULT_QUEUE_URL_HEAD = 'https://sqs.$(process.env.AWS_REGION).amazonaws.com/$(process.env["AWS_ACCOUNT_ID"])/';

export class SQS {
    private _params = {
        DelaySeconds: 0,
        MessageAttributes:{
            "Title": {
                DataType: "String",
                StringValue: "ChunkFlow Task"
            },
            "Author": {
                DataType: "String",
                StringValue: "unknown"
            },
            "WeeksOn": {
                DataType: "Number",
                StringValue: "6"
            }
        },
        MessageBody: "the payload",
        QueueUrl: DEFAULT_QUEUE_URL_HEAD
    }

    constructor(queueName: string = 'chunkflow-inference',
                author: string = "Jingpeng Wu"){
        this._params.QueueUrl = DEFAULT_QUEUE_URL_HEAD + queueName;
        this._params.MessageAttributes.Author.StringValue = author;
    }
    set_queue_name( newName: string ) {
        this._params.QueueUrl = DEFAULT_QUEUE_URL_HEAD + newName;
    }
    get_queue_name() {
        return this._params.QueueUrl.split("/").pop()
    }
    get_queue_url() {
        return this._params.QueueUrl;
    }
    send(message="payload here") {
        this._params.MessageBody = message;
        sqs.sendMessage(this._params, function(err, data){
            if (err) {
                console.log("Error", err);
            } else {
                console.log("Success", data.MessageId)
            }
        });
    }
}
