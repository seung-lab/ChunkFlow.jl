#FROM nvidia/cuda:8.0-cudnn6-devel-ubuntu16.04
FROM nvidia/cuda:8.0-cudnn5-runtime-ubuntu14.04
#FROM ubuntu:16.04
LABEL maintainer Jingpeng Wu

RUN apt-get update 
RUN apt-get install -y -qq --no-install-recommends software-properties-common
RUN add-apt-repository main
RUN add-apt-repository universe
RUN apt-get update
RUN apt-get install --force-yes -qq --no-install-recommends wget build-essential libjemalloc-dev python2.7 python-pip python-setuptools libmagickcore-dev libmagickwand-dev libmagic-dev unzip hdf5-tools libgfortran3 libhdf5-7
ENV LD_PRELOAD=/usr/lib/x86_64-linux-gnu/libjemalloc.so
RUN pip install --upgrade pip

#### install julia
# https://github.com/docker-library/julia/blob/master/Dockerfile
ENV JULIA_PATH /usr/local/julia
ENV JULIA_VERSION 0.5.2

RUN mkdir $JULIA_PATH \
    && apt-get update && apt-get install -y curl \
    && curl -sSL "https://julialang-s3.julialang.org/bin/linux/x64/${JULIA_VERSION%[.-]*}/julia-${JULIA_VERSION}-linux-x86_64.tar.gz" -o julia.tar.gz \
    && curl -sSL "https://julialang-s3.julialang.org/bin/linux/x64/${JULIA_VERSION%[.-]*}/julia-${JULIA_VERSION}-linux-x86_64.tar.gz.asc" -o julia.tar.gz.asc \
    && export GNUPGHOME="$(mktemp -d)" \
# http://julialang.org/juliareleases.asc
# Julia (Binary signing key) <buildbot@julialang.org>
    && gpg --keyserver ha.pool.sks-keyservers.net --recv-keys 3673DF529D9049477F76B37566E3C7DC03D6E495 \
    && gpg --batch --verify julia.tar.gz.asc julia.tar.gz \
    && rm -r "$GNUPGHOME" julia.tar.gz.asc \
    && tar -xzf julia.tar.gz -C $JULIA_PATH --strip-components 1 \
    && rm -rf /var/lib/apt/lists/* julia.tar.gz*

ENV PATH $JULIA_PATH/bin:$PATH

# Cloud environment
RUN pip install gsutil awscli && \
    rm -rf /var/cache/apk/* && \
    rm -rf /var/lib/apt/lists/*
# ADD /usr/people/jingpeng/.google_credentials.json /root/.google_credentials.json
# Julia computational environment
RUN julia -e 'Pkg.init()'
RUN julia -e 'Pkg.update()'
RUN julia -e 'Pkg.clone("https://github.com/seung-lab/Agglomeration.git")'
RUN julia -e 'Pkg.build("Agglomeration")'
RUN julia -e 'Pkg.clone("https://github.com/seung-lab/BigArrays.jl.git")'
RUN julia -e 'Pkg.clone("https://github.com/seung-lab/ChunkFlow.jl.git")'
RUN julia -e 'Pkg.build("ChunkFlow")'
RUN julia -e 'using ChunkFlow'

ENTRYPOINT /bin/bash
WORKDIR /root/.julia/v0.5/ChunkFlow/scripts
