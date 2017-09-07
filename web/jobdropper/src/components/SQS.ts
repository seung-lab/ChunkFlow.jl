import AWS = require('aws-sdk');

let sqs = new AWS.SQS({apiVersion: '2012-11-05'});

const DEFAULT_QUEUE_URL_HEAD = 'https://sqs.us-east-1.amazonaws.com/098703261575/';

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
