FROM nvidia/cuda:8.0-cudnn6-runtime-ubuntu16.04
#FROM nvidia/cuda:8.0-cudnn5-runtime-ubuntu14.04
LABEL   maintainer="Jingpeng Wu" \
        project="ChunkFlow"

#### update repository
RUN apt update 
RUN apt install -y -qq --no-install-recommends software-properties-common
RUN add-apt-repository main
RUN add-apt-repository universe
RUN add-apt-repository restricted
RUN add-apt-repository multiverse
RUN add-apt-repository ppa:staticfloat/julia-deps 
RUN apt-get update
       

#### install some packages
RUN apt-get install -qq --no-install-recommends build-essential wget unzip libjemalloc-dev libhdf5-dev libblosc-dev libmagickwand-6.q16-2 
ENV LD_PRELOAD=/usr/lib/x86_64-linux-gnu/libjemalloc.so 

#### install julia
WORKDIR /opt 
RUN wget https://julialang-s3.julialang.org/bin/linux/x64/0.5/julia-0.5.2-linux-x86_64.tar.gz
RUN tar -xvf julia-0.5.2-linux-x86_64.tar.gz
RUN mv julia-f4c6c9d4bb julia-0.5
ENV JULIA_PATH /opt/julia-0.5 
ENV JULIA_VERSION 0.5.2
ENV PATH $JULIA_PATH/bin:$PATH

# Julia computational environment
RUN julia -e 'Pkg.init()'
RUN julia -e 'Pkg.update()'
RUN julia -e 'Pkg.clone("https://github.com/seung-lab/EMIRT.jl.git")'
RUN julia -e 'Pkg.clone("https://github.com/seung-lab/GSDicts.jl.git")'
RUN julia -e 'Pkg.clone("https://github.com/seung-lab/S3Dicts.jl.git")'
RUN julia -e 'Pkg.clone("https://github.com/seung-lab/BOSSArrays.jl.git")'
RUN julia -e 'Pkg.clone("https://github.com/seung-lab/BigArrays.jl.git")'
RUN julia -e 'Pkg.clone("https://github.com/seung-lab/ChunkFlow.jl.git")'
RUN julia -e 'Pkg.build("ChunkFlow")'
RUN julia -e 'using ChunkFlow'

#### install web server
#WORKDIR /root/.julia/v0.5/ChunkFlow/web/jobdropper
#RUN curl -sL https://deb.nodesource.com/setup_6.x | bash -
#RUN apt-get install -y nodejs
#RUN ln -s /usr/bin/nodejs /usr/bin/node
#RUN apt-get install -y npm 
#RUN npm install --silent --save-dev -g \
#        typescript webpack webpack-dev-server 
#RUN npm install --silent --save-dev
#RUN webpack                                                           
#### reset web server
ENTRYPOINT /bin/bash
WORKDIR /root/.julia/v0.5/ChunkFlow/scripts
