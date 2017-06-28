#FROM nvidia/cuda:8.0-cudnn6-devel-ubuntu16.04
FROM ubuntu:16.04
LABEL maintainer Jingpeng Wu

RUN apt-get update && \
    apt-get install -y -qq --no-install-recommends software-properties-common && \
    add-apt-repository ppa:staticfloat/juliareleases && \ 
    add-apt-repository ppa:staticfloat/julia-deps && \
    apt-get update 

RUN apt-get install -y -qq --no-install-recommends \
        julia=0.5.2 

# Cloud environment
RUN pip install gsutil awscli && \
    rm -rf /var/cache/apk/*
ADD ~/.google_credentials.json /root/.google_credentials.json

# Julia computational environment
RUN julia -e 'Pkg.clone("https://github.com/jingpengw/GoogleCloud.jl.git")'
RUN julia -e 'Pkg.clone("https://github.com/jingpengw/AWSS3.jl.git")'
RUN julia -e 'Pkg.clone("https://github.com/seung-lab/SQSChannels.jl.git")'
RUN julia -e 'Pkg.clone("https://github.com/seung-lab/GSDicts.jl.git")'
RUN julia -e 'Pkg.clone("https://github.com/seung-lab/S3Dicts.jl.git")'
RUN julia -e 'Pkg.clone("https://github.com/seung-lab/BigArrays.jl.git")'
#RUN julia -e 'Pkg.clone("https://github.com/seung-lab/ChunkFlow.jl.git")'

ADD ~/.julia/v0.5/ChunkFlow /root/.julia/v0.5/

ENTRYPOINT /bin/bash

WORKDIR /root/.julia/v0.5/ChunkFlow/scripts
