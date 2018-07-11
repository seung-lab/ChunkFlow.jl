
export class TaskTemplate {
    private _template: any;

    constructor(data: string = DEFAULT_TEMPLATE){
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
    "kind": "EdgeCutoutChunk",                                 
    "params":{                                                 
        "bigArrayType": "s3",                                  
        "inputOffset":  [4896, 4896, 940],                                 
        "cutoutSize": [1120, 1120,  126],                         
        "nonzeroRatioThreshold": 0.00,
        "inputPath": "s3://path/to/layer/6_6_30/" 
    },
    "outputs":{
        "chunk": "img"                        
    }      
}, 
"CPUInference":{
    "kind": "EdgePZNet",
    "params":{
        "convnetPath"       : "/import/s1/cores4",
        "patchSize"         : [160, 160, 18],
        "patchOverlap"      : [80, 80,9],
        "outputLayerName"   : "output",
        "outputChannelNum"  : 3,
        "cropMarginSize"    : [64, 64, 4,0]
    },
    "inputs": {
        "img": "img"
    },
    "outputs": {
        "chunk": "aff"
    }
},
"saveaff":{                                
    "kind": "EdgeSaveChunk",                                           
    "params": {                                                       
        "backend": "s3",                                                 
        "outputPath": "s3://path/to/layer/6_6_30/" 
    },                                                                    
    "inputs": {                                     
        "chunk": "aff"                                                           
    } 
}                                                                         
}
`
