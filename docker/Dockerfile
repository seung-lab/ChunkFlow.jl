FROM nvidia/cuda:8.0-cudnn6-devel-ubuntu16.04
#FROM ubuntu:16.04
LABEL maintainer Jingpeng Wu

RUN apt-get update 
RUN apt-get install -y -qq --no-install-recommends wget \
    build-essential \
    python2.7 python-pip python-setuptools
RUN pip install --upgrade pip
#RUN apt-get install -y -qq --no-install-recommends julia=0.5 
RUN wget --no-check-certificate https://julialang-s3.julialang.org/bin/linux/x64/0.5/julia-0.5.2-linux-x86_64.tar.gz  
RUN tar -xvf julia-0.5.2-linux-x86_64.tar.gz 
RUN ln -s julia-f4c6c9d4bb/bin/julia /usr/local/bin/julia

# Cloud environment
RUN pip install gsutil awscli && \
    rm -rf /var/cache/apk/*
# ADD /usr/people/jingpeng/.google_credentials.json /root/.google_credentials.json

# Julia computational environment
# RUN julia -e 'Pkg.clone("https://github.com/seung-lab/ChunkFlow.jl.git")'

COPY ../../ChunkFlow /root/.julia/v0.5/
RUN julia -e 'Pkg.build("ChunkFlow")'
RUN julia -e 'using ChunkFlow'
ENTRYPOINT /bin/bash

WORKDIR /root/.julia/v0.5/ChunkFlow/scripts
