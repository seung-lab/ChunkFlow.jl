
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
    "kind": "cutoutchunk",
    "params":{
        "bigArrayType": "s3",
        "origin":   [4065, 4065, 1021],
        "cutoutSize": [2112, 2112,  72],
        "voxelSize": [6,6,30],
        "nonzeroRatioThreshold": 0.00000001
    },
    "inputs": {
      "path": "s3://neuroglancer/s1_v1/image/6_6_30/"
    },
    "outputs": {
        "data": "img"
    }
},
"ConvNetJNet":{
    "kind": "kaffe",
    "params":{
        "kaffeDir"          : "/opt/kaffe",
        "caffeModelFile"    : "s3://neuroglancer/s1_v1/affinitymap/convnets/deploy.prototxt",
        "caffeNetFile"      : "s3://neuroglancer/s1_v1/affinitymap/convnets/train_iter_600000.caffemodel.h5",
        "caffeNetFileMD5"   : "eb09961c5a4d01687e44f872bcbcbd74",
        "outputPatchSize"   : [160, 160,  18],
        "scanParams"        : "dict(stride=(0.5,0.5,0.5), blend='bump')",
        "preprocess"        : "divideby",
        "batchSize"         : 1,
        "deviceID"          : 0,
        "cropMarginSize"    : [32, 32, 4,0],
        "originOffset"      : [32, 32, 4,0],
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
"blendaffinity":{
    "kind": "blendchunk",
    "params":{
      "backend": "s3"
    },
    "inputs": {
        "chunk": "aff"
    },
    "outputs": {
        "path": "s3://neuroglancer/s1_v1/affinitymap/6_6_30/"
    }
}
}
`
