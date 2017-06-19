# Inputs


### read from hdf5 file

```json
"input": {
    "kind": "readh5",
    "params":{
        "origin": [],
        "voxelSize": [5,5,45],
        "datasetName": "image",
        "isRemoveSourceFile": false
    },
    "inputs": {
        "fileName": "../assets/zfish_25397_8001_1.img.h5"
    },
    "outputs": {
        "data": "img"
    }
},
```

### read chunk

```json
"input": {
    "kind": "readchunk",
    "params":{
        "origin": [],
        "chunkSize": [2048,2048,256],
        "voxelSize": [4,4,40]
    },
    "inputs": {
        "prefix": "s3://seunglab/pinky/all/imagechunks/chunk_",
        "suffix": ".img.h5"
    },
    "outputs": {
        "data": "img"
    }
},
```


## cutoutchunk

### cutout from 2D aligned image sections

```json
"input": {
    "kind": "cutoutchunk",
    "params":{
        "bigArrayType": "aligned",
        "origin":   [20001, 25001, 4001],
        "chunkSize":     [1132, 1132, 260],
        "originOffset": [-16384,-16384,-16384], # change the origin before cutout
        "offset":       [16384,16384,16384],    # change the offset after cutout
        "isRemoveNaN":  false, # optional, remove NaN elements
        "voxelSize": [4,4,40]
    },
    "inputs": {
      "registerFile": "/mnt/data01/datasets/pinky/4_aligned/registry.txt"
    },
    "outputs": {
        "data": "img"
    }
},
```

### cutout from 3D HDF5 cubes

```json
"input": {
    "kind": "cutoutchunk",
    "params":{
        "bigArrayType": "h5s",
        "origin":   [12235, 4043, 4001],
        "chunkSize":     [1132, 1132, 260],
        "voxelSize": [4,4,40]
    },
    "inputs": {
      "h5sDir": "/mnt/data01/datasets/pinky/5_finished/10percent"
    },
    "outputs": {
        "data": "img"
    }
},
```


### cutout from Google Cloud Storage or AWS S3

```json
"input": {
    "kind": "cutoutchunk",
    "params":{
        "bigArrayType": "gs", | "s3"
        "origin":   [-15413, -6197, -3],
        "chunkSize": [1132, 1132,  136],
        "offset":    [16384,16384,16384],
        "voxelSize": [4,4,40],
        "nonzeroRatioThreshold": 0.01
    },
    "inputs": {
      "path": "gs://bucket/key1/subkey2/"
    },
    "outputs": {
        "data": "img"
    }
},
```

### cutout from image tiles in [DVID](https://github.com/janelia-flyem/dvid)

```json
"input": {
    "kind": "cutoutchunk",
    "params":{
        "bigArrayType": "dvidimagetile",
        "port": 8000,
        "node": "5c",
        "origin":   [12235, 4043, 4001],
        "chunkSize":     [1132, 1132, 260],
        "voxelSize": [4,4,40]
    },
    "inputs": {
      "address": "localhost"
    },
    "outputs": {
        "data": "img"
    }
},
```

### use a reference chunk to get origin

```json
"input_img": {
    "kind": "cutoutchunk",
    "params":{
        "bigArrayType": "aligned", 
        "chunkSize":    [1024,   1024,    252],
        "voxelSize":    [4,     4,      40]
    },
    "inputs": {
      "registerFile": "/mnt/data01/datasets/pinky/4_aligned/registry.txt",
      "referenceChunk": "sgm"
    },
    "outputs": {
        "data": "img"
    }
},
```

# save

## saveh5
```json
"saveh5":{
    "kind": "saveh5",
    "params": {
        "datasetName": "img",
        "compression": "deflate",
        "fileNamePrefix": "gs://zfish/affinitymap/block_"
    },
    "inputs": {
        "chunk": "aff"
    },
    "outputs": {}
},
```

## savechunk

```json
"saveaff":{
    "kind": "savechunk",
    "params": {},
    "inputs": {
        "chunk": "aff"
    },
    "outputs": {
        "prefix": "s3://zfish/dodam_aligned_stacks/2x2x2_2/affinityMap/chunk_"
    }
},
```

## blendchunk

save chunk to bigarray

```json
"blendaffinity":{
    "kind": "blendchunk",
    "params":{
        "backend": "h5s" | "gs" | "s3" | "boss",
        "chunkSize": [512,512,16]
    },
    "inputs": {
        "chunk": "aff"
    },
    "outputs": {
        "bigArrayDir": "/tmp/testBigArray"
    }
},
```

### blend chunk to Google Cloud Storage
```json
"blendsegmentation":{
    "kind": "blendchunk",
    "params":{
        "backend": "gs"
    },
    "inputs": {
        "chunk": "seg"
    },
    "outputs": {
        "path": "gs://neuroglancer/snemi3dtest_v0/segmentation_jwu/6_6_30/"
    }
}
```

### cutout and save images
normally used for checking the correctness across chunk boundaries

```json
"savepng":{
    "kind": "savepng",
    "params":{
        "outputDir"   : "s3://neuroglancer/pinky40_v8/affinitymap-jnet/cutouts/"
    },
    "inputs": {
        "chunk" : "aff"
    },
    "outputs": {}
}
```

## omnification

```json
"omnification":{
    "kind": "omnification",
    "params":{
        "ombin": "/opt/omni",
        "isMeshing": true
    },
    "inputs": {
        "img": "img",
        "sgm": "sgm"
    },
    "outputs": {
        "prefix": "~/seungmount/research/Jingpeng/13_neuromancer/pinky/chunk_"
    }
}
```

## hypersquare

```json
"hypersquare":{
    "kind": "hypersquare",
    "params":{
        "segment_id_type" : "UInt16",
        "affinity_type" : "Float32"
    },
    "inputs": {
        "img": "img",
        "sgm": "sgm"
    },
    "outputs": {
        "projectsDirectory": "s3://zfish/dodam_aligned_stacks/2x2x2_2/hypersquare/"
    }
}
```

# Convnet inference
## kaffe

### multiscale

```json
"ConvNetJNet":{
    "kind": "kaffe",
    "params":{
        "kaffeDir"          : "/opt/kaffe",
        "caffeModelFile"    : "s3://seunglab/pinky40_2/convnets/affinitymap/JNet/deploy.prototxt",
        "caffeNetFile"      : "s3://seunglab/pinky40_2/convnets/affinitymap/JNet/train_iter_400000.caffemodel.h5",
        "caffeNetFileMD5" : "dbd3be9c440ada66c1fae951038be13a",
        "outputPatchSize"   :    [256, 256,  24],
        "scanParams"        : "dict(stride=(0.5,0.5,0.5), blend='bump')",
        "preprocess"        : "divideby",
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
```

### JNet
```json
"MSF":{
    "kind": "kaffe",
    "params":{
        "kaffeDir": "/opt/kaffe",
        "caffeModelFile": "/opt/kaffe/models/MSF/deploy.prototxt",
        "caffeNetFile": "/opt/kaffe/experiments/zfish/MSF/train_iter_250000.caffemodel.h5",
        "outputPatchSize":    [150, 150,  12],
        "scanParams": "None",
        "deviceID": 0,
        "isCropImg": true,
        "cropMarginSize": [6,   6,    0],
        "originOffset": [54, 54, 4],
        "affWeight": 0.33333333
    },
    "inputs": {
        "img": "img",
        "aff": "aff"
    },
    "outputs": {
        "aff": "aff"
    }
},
```

## ZNNi

### multiscale
```json
"znni":{
    "kind": "znni",
    "params":{
        "znniBinaryFile": "/opt/ZNNi/code/bin/multiscale/znni_gpu",
        "deviceID": 0,
        "fnet": "s3://znn/experiments/zfish/net_290000.h5",
        "outputPatchSize": [256, 256, 17],
        "fieldOfView": [109, 109, 9],
        "isExchangeAffXZ": true,
        "affWeight": 0.333333333
    },
    "inputs": {
        "img": "img",
        "aff": "aff"
    },
    "outputs": {
        "aff": "aff"
    }
},
```

# Processing

## watershed

```json
"watershed":{
    "kind": "atomicseg",
    "params": {
        "low": 0.1,
        "high": 0.8,
        "thresholds": [
            {
                "size": 800,
                "threshold": 0.2
            }
        ],
        "dust": 600,
        "isThresholdRelative": true
    },
    "inputs": {
        "aff": "aff"
    },
    "outputs": {
        "seg": "seg"
    }
},
```

## agglomeration
```json
"agglomeration":{
    "kind":"agglomeration",
    "params":{
        "mode": "mean",
        "isDeleteAff": true
    },
    "inputs": {
        "seg": "seg",
        "aff": "aff"
    },
    "outputs": {
        "sgm": "sgm"
    }
},
```

# Manipulation

## downsample
```json
"donwsample":{
    "kind": "downsample",
    "params":{
        "scale": [8,8,1,1],
    },
    "inputs":{
        "chunk": "aff"
    },
    "outputs":{
        "chunk": "aff"
    }
},
```

## crop

```json
"cropImg":{
  "kind": "crop",
  "params": {
    "cropMarginSize": [54, 54, 4]
  },
  "inputs":{
    "img": "img"
  },
  "outputs":{
    "img": "img"
  }
},
```

## remove affinity edges in black image regions

use threshold to make a binary mask. The lower intensity voxels were masked as `true`.
use **2D** connectivity analysis to detect the region sizes in each section.

```json
"maskaff":{
    "kind": "maskaffinity",
    "params": {
        "sizeThreshold": 400, # optional, without this, will not do connectivity analysis
    },
    "inputs": {
        "img": "img",
        "aff": "aff"
    },
    "outputs": {
        "aff": "aff"
    }
},
```

## remove data from dictchannel

```json
"removeaff":{
    "kind": "remove",
    "params": {},
    "inputs": {
        "datas": ["aff"]
    },
    "outputs": {}
},
```

## merge supervoxels by thresholding 
thresholding the MST, and merge some supervoxels to get a plain segmentation
```json
"merge":{
    "kind": "mergeseg",
    "params": {
         "threshold": 0.3
    },
    "inputs": {
        "sgm": "sgm"
    },
    "outputs": {
        "seg": "seg"
    }
},
```
