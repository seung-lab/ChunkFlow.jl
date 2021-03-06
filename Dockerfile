#FROM nvidia/cuda:8.0-cudnn6-runtime-ubuntu16.04
#FROM jingpengw/kaffe
#FROM seunglab/kaffe:pznet
#FROM nvidia/cuda:8.0-cudnn5-runtime-ubuntu14.04
FROM jingpengw/chunkflow:latest
LABEL   maintainer="Jingpeng Wu" \
        project="ChunkFlow"


#### update repository
RUN apt update 
#RUN apt install -y -qq --no-install-recommends software-properties-common
#RUN add-apt-repository main
#RUN add-apt-repository universe
#RUN add-apt-repository restricted
#RUN add-apt-repository multiverse
#RUN add-apt-repository ppa:staticfloat/julia-deps 
#RUN apt-get update
       
#### install some packages
RUN apt-get install -qq --no-install-recommends build-essential wget unzip libjemalloc-dev libhdf5-dev libblosc-dev libmagickwand-6.q16-2 python-dev python-pip  
RUN pip install --upgrade pip
RUN pip install -U setuptools 
RUN pip install awscli gsutil  
#RUN pip install protobuf google cloud-volume

ENV LD_PRELOAD=/usr/lib/x86_64-linux-gnu/libjemalloc.so 

# install gcloud
ENV PATH /opt/google-cloud-sdk/bin:$PATH
RUN pip install -U crcmod
RUN mkdir -p /opt/gcloud && \
    wget --no-check-certificate --directory-prefix=/tmp/ https://dl.google.com/dl/cloudsdk/release/google-cloud-sdk.zip && \
    unzip /tmp/google-cloud-sdk.zip -d /opt/ && \
    /opt/google-cloud-sdk/install.sh --usage-reporting=true --path-update=true --bash-completion=true --rc-path=/opt/gcloud/.bashrc --disable-installation-options && \
    gcloud --quiet components update app preview alpha beta app-engine-java app-engine-python kubectl bq core gsutil gcloud && \
    rm -rf /tmp/*
#RUN gcloud auth activate-service-account --key-file /secrets/google-secret.json 

#### install julia
WORKDIR /opt 
RUN wget https://julialang-s3.julialang.org/bin/linux/x64/0.6/julia-0.6.4-linux-x86_64.tar.gz
RUN tar -xvf julia-0.6.4-linux-x86_64.tar.gz 
RUN mv julia-9d11f62bcb julia-0.6
ENV JULIA_PATH /opt/julia-0.6 
ENV JULIA_VERSION 0.6.4 
ENV PATH $JULIA_PATH/bin:$PATH 

# Julia computational environment
RUN julia -e 'Pkg.init()'
RUN julia -e 'Pkg.update()'
# fix some warnings since FFTW was removed from base and some packages needs it.
RUN julia -e 'Pkg.add("FFTW")'
RUN julia -e 'Pkg.clone("https://github.com/JuliaWeb/HTTP.jl.git")'
RUN julia -e 'Pkg.clone("https://github.com/samoconnor/SymDict.jl.git")'
RUN julia -e 'Pkg.clone("https://github.com/JuliaCloud/AWSCore.jl.git")'
RUN julia -e 'Pkg.clone("https://github.com/JuliaCloud/AWSSDK.jl.git")'
RUN julia -e 'Pkg.clone("https://github.com/samoconnor/AWSSQS.jl.git")'
RUN julia -e 'Pkg.clone("https://github.com/seung-lab/EMIRT.jl.git")'

RUN julia -e 'Pkg.clone("https://github.com/seung-lab/BigArrays.jl.git")'
#RUN julia -e 'Pkg.checkout("BigArrays", "fast")'
#RUN julia -e 'Pkg.clone("https://github.com/seung-lab/BOSSArrays.jl.git")'
#RUN julia -e 'Pkg.clone("https://github.com/seung-lab/CloudVolume.jl.git")'
RUN julia -e 'Pkg.clone("https://github.com/seung-lab/ChunkFlow.jl.git")'

#WORKDIR /root/.julia/v0.6 
#RUN mkdir ChunkFlow 
#ADD . ChunkFlow 

RUN julia -e 'Pkg.resolve()'
RUN julia -e 'Pkg.test("BigArrays")'
RUN julia -e 'Pkg.build("ChunkFlow")'
RUN julia -e 'using ChunkFlow'


#ENTRYPOINT /bin/bash
WORKDIR /root/.julia/v0.6/ChunkFlow/scripts
