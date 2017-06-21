
| data type       | data representation  | note  |
| ----------------|:--------------------:| -----:|
| raw image stack | z,y,x                |       |
| affinity        | c,z,y,x              | the channels 0,1,2 represent **x,y,z** respectively     |
| segmentation    | z,y,x                |       |
| ZNN feature map | n_in,n_out,z,y,x     |       |
| ZNNi feature map| n_in,n_out,z,y,x     | we have a znn_helper function to transform, the internal format is n_out,n_in,x,y,z      |


no matter whether it is row-major or column-major, the **x** always neighboring each other in memory.

- n_in: number of input feature maps
- n_out: number of output feature maps
