#FROM nvidia/cuda:8.0-cudnn6-devel-ubuntu16.04
# based on https://github.com/Kaggle/docker-julia/blob/master/Dockerfile
FROM ubuntu:16.04
LABEL maintainer Jingpeng Wu

RUN apt-get update && \
    apt-get install -y -qq --no-install-recommends software-properties-common && \
    add-apt-repository ppa:staticfloat/juliareleases && \ 
    add-apt-repository ppa:staticfloat/julia-deps && \
    apt-get update 

RUN apt-get install -y -qq --no-install-recommends \
        julia 
RUN julia -e "Pkg.clone(\"https://github.com/seung-lab/ChunkFlow.jl.git\")"


WORKDIR /root/.julia/v0.5/ChunkFlow/scripts
