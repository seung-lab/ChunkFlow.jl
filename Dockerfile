FROM julialang/julia:v0.5.1
MAINTAINER Jingpeng Wu

# Cloud environment
RUN pip install gsutil awscli && \
    rm -rf /var/cache/apk/*
ADD ~/.google_credentials.json /root/.google_credentials.json

# Julia computational environment
RUN julia -e 'Pkg.clone("https://github.com/seung-lab/SQSChannels.jl.git")'
RUN julia -e 'Pkg.clone("https://github.com/seung-lab/GSDicts.jl.git")'
RUN julia -e 'Pkg.clone("https://github.com/seung-lab/S3Dicts.jl.git")'
RUN julia -e 'Pkg.clone("https://github.com/seung-lab/BigArrays.jl.git")'
RUN julia -e 'Pkg.clone("https://github.com/seung-lab/ChunkFlow.jl.git")'

ENTRYPOINT /bin/bash 
