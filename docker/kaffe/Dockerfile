FROM jingpengw/kaffe
#FROM sergiypopo/cpu_inference:latest
#FROM nvidia/cuda:8.0-cudnn6-runtime-ubuntu16.04
#FROM nvidia/cuda:8.0-cudnn5-runtime-ubuntu14.04
LABEL   maintainer="Jingpeng Wu" \
        project="ChunkFlow"

#### update repository
#RUN apt update 
#RUN apt install -y -qq --no-install-recommends software-properties-common
#RUN add-apt-repository main
#RUN add-apt-repository universe
#RUN add-apt-repository restricted
#RUN add-apt-repository multiverse
RUN apt-get update

#### install some packages
RUN apt-get install -qq --no-install-recommends build-essential wget unzip libjemalloc-dev libhdf5-dev libblosc-dev libmagickwand-6.q16-2 python-dev python-pip git  
RUN pip install --upgrade pip
#RUN pip install -U setuptools 
#RUN pip install protobuf google cloud-volume

ENV LD_PRELOAD=/usr/lib/x86_64-linux-gnu/libjemalloc.so 

#### install caffe
# install kaffe and patchprovider
#WORKDIR /opt 
#RUN rm -rf caffe
#RUN git clone https://github.com/torms3/caffe.git  
#RUN git clone https://github.com/torms3/kaffe.git
#RUN git clone https://github.com/jingpengw/patchprovider.git 
#WORKDIR /opt/patchprovider 
#RUN pip install -r requirements_dev.txt
#ENV PYTHONPATH /opt/patchprovider:$PYTHONPATH
#ENV PYTHONPATH /opt/kaffe:$PYTHONPATH
#ENV PYTHONPATH /opt/kaffe/layers:$PYTHONPATH

#### install julia
WORKDIR /opt 
RUN wget https://julialang-s3.julialang.org/bin/linux/x64/0.6/julia-0.6.1-linux-x86_64.tar.gz 
RUN tar -xvf julia-0.6.1-linux-x86_64.tar.gz
RUN mv julia-0d7248e2ff julia
ENV JULIA_PATH /opt/julia  
ENV JULIA_VERSION 0.6.1
ENV PATH $JULIA_PATH/bin:$PATH

# Julia computational environment
RUN julia -e 'Pkg.init()'
RUN julia -e 'Pkg.update()'
RUN julia -e 'Pkg.clone("https://github.com/samoconnor/SymDict.jl.git")'
RUN julia -e 'Pkg.clone("https://github.com/JuliaCloud/AWSCore.jl.git")'
RUN julia -e 'Pkg.clone("https://github.com/samoconnor/AWSSQS.jl.git")'
RUN julia -e 'Pkg.clone("https://github.com/seung-lab/EMIRT.jl.git")'
RUN julia -e 'Pkg.clone("https://github.com/seung-lab/H5SectionsArrays.jl.git")'
RUN julia -e 'Pkg.clone("https://github.com/seung-lab/GSDicts.jl.git")'
RUN julia -e 'Pkg.clone("https://github.com/seung-lab/S3Dicts.jl.git")'
RUN julia -e 'Pkg.clone("https://github.com/seung-lab/BOSSArrays.jl.git")'
RUN julia -e 'Pkg.checkout("BigArrays")'
#RUN julia -e 'Pkg.clone("https://github.com/seung-lab/CloudVolume.jl.git")'
RUN julia -e 'Pkg.clone("https://github.com/seung-lab/ChunkFlow.jl.git")'

#RUN julia -e 'Pkg.checkout("CloudVolume")'
##WORKDIR /root/.julia/v0.6/CloudVolume
#RUN git pull & git checkout julia0.6
#RUN julia -e 'Pkg.checkout("CloudVolume", "julia0.6")'
RUN julia -e 'Pkg.build("ChunkFlow")'
RUN julia -e 'using ChunkFlow'

# finallize
WORKDIR /root/.julia/v0.6/ChunkFlow/scripts
ENTRYPOINT julia main.jl -q chunkflow-inference
