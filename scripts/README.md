# produce test tasks of golden cube
```
julia produce_starts.jl -q chunkflow-inference -o -25,-25,-8 -s 1024,1024,128 -g 2,2,2
```

# ConvNet Inference

```
julia async_inference.jl -q chunkflow-inference -i s3://neuroglancer/pinkygolden_v0/image/4_4_40 -y s3://neuroglancer/pinkygolden_v0/affinitymap-rs-unet-cremi/4_4_40 -v /import/rs-unet-cremi-4cores -d -1 -s 1024,1024,128
```
