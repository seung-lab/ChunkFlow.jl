FROM node

# Install node packages
RUN npm install --silent --save-dev -g \
        typescript webpack webpack-dev-server

RUN mkdir /app
WORKDIR /app 
#RUN git clone https://github.com/seung-lab/ChunkFlow.jl.git
#WORKDIR ChunkFlow.jl/web/jobdropper
ADD src ./src 
ADD *.js* ./
ADD *.html ./ 

RUN npm install --silent --save-dev 
RUN webpack

EXPOSE 80
CMD ["webpack-dev-server", "--host", "0.0.0.0"]
