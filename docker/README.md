
# compile pznet

[original documentation](https://github.com/seung-lab/seunglab-wiki#pznet)

```
sudo docker run -it -v /opt/intel/licenses:/opt/intel/licenses -v /import:/import seunglab/pznet:devel
```

```
cd /opt/znnphi_interface/code/scripts
python sergify.py -n {/path/to/net.prototxt} -w {/path/to/weights.h5} -o {/output/path}
```
