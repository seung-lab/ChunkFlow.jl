## make docker login to AWS
our docker image repo is in [AWS EC2 Container Service](https://console.aws.amazon.com/ecs/home?region=us-east-1#/repositories/chunkflow#images), so if your docker image was not downloaded, you need authorization from AWS.

### Install AWSCLI
    pip install awscli
    aws configure
put your ID and key, set region to be `us-east-1`

### get login authorization
    aws ecr get-login
you'll get the command to make `docker` login to AWS, run it with `sudo`

## Pipeline in local workstation or GPU server

[directly run pipeline using docker image](http://timmurphy.org/2015/02/27/running-multiple-programs-in-a-docker-container-from-the-command-line/) (recommemded)

    sudo nvidia-docker run --net=host -i -t -v /mnt/data01:/mnt/data01 -v /mnt/data02:/mnt/data02 -v ~/seungmount:/root/seungmount 098703261575.dkr.ecr.us-east-1.amazonaws.com/chunkflow:v1.2.3 bash -c 'source /root/.bashrc  && export PYTHONPATH=$PYTHONPATH:/opt/caffe/python && export PYTHONPATH=$PYTHONPATH:/opt/kaffe/layers && export PYTHONPATH=$PYTHONPATH:/opt/kaffe && export LD_LIBRARY_PATH=${LD_LIBRARY_PATH}:/opt/caffe/build/lib && julia -O3 --check-bounds=no --math-mode=fast -p 10 /root/.julia/v0.5/ChunkFlow/scripts/main.jl -a pinky-inference -w 10 -d 0'

    sudo nvidia-docker run --net=host -i -t -v /mnt/data01:/mnt/data01 -v /mnt/data02:/mnt/data02 -v ~/seungmount:/root/seungmount 098703261575.dkr.ecr.us-east-1.amazonaws.com/chunkflow:v1.2.3 bash -c 'source /root/.bashrc  && export PYTHONPATH=$PYTHONPATH:/opt/caffe/python && export PYTHONPATH=$PYTHONPATH:/opt/kaffe/layers && export PYTHONPATH=$PYTHONPATH:/opt/kaffe && export LD_LIBRARY_PATH=${LD_LIBRARY_PATH}:/opt/caffe/build/lib && julia -O3 --check-bounds=no --math-mode=fast -p 16 /root/.julia/v0.5/ChunkFlow/scripts/main.jl -a zfish-seg'

You can also hack into the docker image:

    sudo nvidia-docker run --net=host -i -t -v /mnt/data01:/mnt/data01 -v /mnt/data02:/mnt/data02 -v ~/seungmount:/root/seungmount 098703261575.dkr.ecr.us-east-1.amazonaws.com/chunkflow:v1.2.2 bash

and then run pipeline

    cd ~/.julia/v0.5/ChunkFlow/scripts/; julia -O3 --check-bounds=no --math-mode=fast main.jl -a pinky-stage-1 -d 0


## Pipeline in AWS instances
### mount the local instance storage

    lsblk
    sudo mkfs.ext4 /dev/xvdb
    sudo mkfs.ext4 /dev/xvdc
    sudo mount /dev/xvdb /tmp
    sudo mount /dev/xvdc /mnt


#### user_data in cpu instances for segmentation
```
#!/bin/bash

#apt-get update && apt-get install -y nfs-common
#mkfs -t ext4 /dev/xvdca
#mount /dev/xvdca /tmp

eval "$(aws ecr get-login)"

docker run --net=host -i 098703261575.dkr.ecr.us-east-1.amazonaws.com/chunkflow:v1.2.4 bash -c 'source /root/.bashrc  && export PYTHONPATH=$PYTHONPATH:/opt/caffe/python && export PYTHONPATH=$PYTHONPATH:/opt/kaffe/layers && export PYTHONPATH=$PYTHONPATH:/opt/kaffe && export LD_LIBRARY_PATH=${LD_LIBRARY_PATH}:/opt/caffe/build/lib && julia -O3 --check-bounds=no --math-mode=fast -p 4 ~/.julia/v0.5/ChunkFlow/scripts/main.jl -w 2 -a pinky-segment'
```

#### user_data in p2.xlarge instance
```
#!/bin/bash

#apt-get update && apt-get install -y nfs-common
#mkfs -t ext4 /dev/xvdca
#mount /dev/xvdca /tmp

eval "$(aws ecr get-login)"

nvidia-docker run --net=host -i 098703261575.dkr.ecr.us-east-1.amazonaws.com/chunkflow:v1.4.2 bash -c 'source /root/.bashrc  && export PYTHONPATH=$PYTHONPATH:/opt/caffe/python && export PYTHONPATH=$PYTHONPATH:/opt/kaffe/layers && export PYTHONPATH=$PYTHONPATH:/opt/kaffe && export LD_LIBRARY_PATH=${LD_LIBRARY_PATH}:/opt/caffe/build/lib && julia -O3 --check-bounds=no --math-mode=fast -p 2 ~/.julia/v0.5/ChunkFlow/scripts/main.jl -w 2 -a pinky-inference'
```

#### user_data in p2.8xlarge instance
```
#!/bin/bash
apt-get update && apt-get install -y nfs-common
# mkdir /mnt/channel
# mkdir /mnt/affinity
mount -t nfs 172.31.39.101:/mnt/channel /mnt/channel
mount -t nfs 172.31.39.101:/mnt/affinity /mnt/affinity

mount --bind /mnt/channel/ /mnt/channel/ && sudo mount --make-shared /mnt/channel/
mount --bind /mnt/affinity/ /mnt/affinity/ && sudo mount --make-shared /mnt/affinity/
su ubuntu -c 'eval "$(aws ecr get-login)"'

for GPU_ID in {0..7}
do
stdbuf -oL -eL su ubuntu -c "nohup sudo nvidia-docker run --net=host -i -v /mnt/channel:/mnt/data01/datasets/zebrafish/4_aligned -v /mnt/affinity:/root/seungmount/research/Jingpeng/14_zfish/jknet/4x4x4/affinitymap 098703261575.dkr.ecr.us-east-1.amazonaws.com/chunkflow:v1.2.3 bash -c 'source /root/.bashrc  && export PYTHONPATH=$PYTHONPATH:/opt/caffe/python && export PYTHONPATH=$PYTHONPATH:/opt/kaffe/layers && export PYTHONPATH=$PYTHONPATH:/opt/kaffe && export LD_LIBRARY_PATH=${LD_LIBRARY_PATH}:/opt/caffe/build/lib && julia -O3 --check-bounds=no --math-mode=fast -p 2 ~/.julia/v0.5/ChunkFlow/scripts/main.jl -d $GPU_ID -a pinky-inference'" &> ~/log${GPU_ID}.txt &
done
```

Note that there [should not be `-t` with docker run](http://stackoverflow.com/questions/29380344/docker-exec-it-returns-cannot-enable-tty-mode-on-non-tty-input)

# disk merging of d2.2xlarge
there are multiple disks in d2 instances, we can use `lvm` to merge the disks as one giant disk.

    pvcreate /dev/xvdca /dev/xvdcb /dev/xvdcc /dev/xvdcd /dev/xvdce /dev/xvdcf
    vgcreate data /dev/xvdca /dev/xvdcb /dev/xvdcc /dev/xvdcd /dev/xvdce /dev/xvdcf
    vgscan
    lvcreate --name data --size 10T data
    mkfs.ext4 /dev/data/data 
    mount /dev/data/data /mnt/data01


