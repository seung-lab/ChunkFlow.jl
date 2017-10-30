
export class TaskTemplate {
    private _template: any;

    constructor(data: string = DEFAULT_TEMPLATE){
        //let data = '{"input": {"origin": [1,2,3]}, "id":229, "name":"John"}';
        this._template = JSON.parse(data);
    }
    parse(newValue: string){
        this._template = JSON.parse(newValue)
    }
    stringify(start: number[]=[0,0,0]){
		console.log(this._template.input.params.origin)
        this._template.input.params.origin = start;
        return JSON.stringify( this._template );
    }
}

const DEFAULT_TEMPLATE = `
{"input": {
    "kind": "NodeCutoutChunk",
    "params":{
        "bigArrayType": "s3",
        "origin":   [1, 1, 1],
        "cutoutSize": [524, 524,  68],
        "voxelSize": [4,4,40],
        "nonzeroRatioThreshold": 0.01,
        "inputPath": "s3://neuroglancer/pinkygolden_v0/image/4_4_40/"
    },
    "inputs": {
    },
    "outputs": {
        "data": "img"
    }
},
"CPUInferenceUNet":{
    "kind": "NodeKaffe",
    "params":{
        "kaffeDir"          : "/opt/kaffe",
        "scanParams"        : "dict(stride=(0,0,0))",
        "preprocess"        : "divideby",
        "batchSize"         : 1,
        "cropMarginSize"    : [0, 0, 0,0],
        "originOffset"      : [0, 0, 0,0],
        "affWeight"         : 1.0
    },
    "inputs": {
        "img": "img",
        "aff": "aff"
    },
    "outputs": {
        "aff": "aff"
    }
},
"saveaff":{
    "kind": "NodeBlendChunk",
    "params": {
        "backend": "s3",
        "outputPath": "s3://neuroglancer/pinkygolden_v0/affinitymap-cpu/4_4_40/"
    },
    "inputs": {
        "chunk": "aff"
    },
    "outputs": {}
}
}
`
