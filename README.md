AWS-ZNN
=======

* Aligment folder should contain all aligned tif images, which should have applied any filter ( unless the znn was trained with that filter)
* Starcluster folder includes a config file for MIT's starcluster, which is a software for managing clusters, this folder include the key-pair 
for accessing the cluster and other sensitive information, DO NOT SHARED THIS REPO
* aws-upload is where most of the magic happends, this folder is meant to be uploaded to aws, to a drive which is shared by network with the hole cluster,
all the data and software required for processing is stored here.

aws-upload folder:
* network_instance and network_spec contains our trained network , again , THIS IS CONFIDENTIAL
* znn-release is the source code for znn , with is compiled when starting the cluster
* watershed will have the source code , ask aleks about with version to use
* data folder ( is created after run chuncking script)
* scheduleJobs.sh is the only thing to run once the server is up, this create all the jobs, which are assigned to each node using Oracle Grid Engine.

aws-upload/script
* chunckStack.py  generate data folder and schedulejobs.sh
* stack.py is a module responsable manging the data inside alignment, this include generate and hdf5 file requiered for omnifying
* znn.py is a module with util methods for generate the text file which specifies trainning and data for znn.
* watershed.py merges the raw double output from znn and convertes it to hdf5, and run the binaries to process that file
* omnify.py splits(if required) the hdf5 output from watershed( stack.py channel data dimensions have to agree) an run omnify parallely

TODO list
=========
* Modify stack.py to work with the file organization of Tommy
* omnify.py should have the logic (if requiered) to convert watershed output in the hdf5 required by omni, and submit the jobs so this can be run parallely. Also it should write an script to rsync the omni(s) project back to princeton. (Do we want to also download other data back?)

Long-term TODO list
===================
* Improve documention of the hole pipeline , make sure to explain, layout of array in disks, there were many bugs primarely because znn asumes column-major, and python uses row-major order.
* Upload chunks for znn to hard drives attach directly to the nodes, faster upload/download speed , better disk I/O . But if a node goes does, data has to be resent, is harder to manage for the scheduler.
* Make a cluster version of watershed, where each chunk is processed in each node, and there are internode comnuication to fix the boundaries.
* Make a cluster version of omni, where chunks are process in each node and then merge in a single project. Our current version of omni doesn't even omnify. Make a separate project for omnifying, so as to simplify omni.
* Make HDF5 as the standar input and output of each stage in the pipeline.
* move from SGE to a possible better mantain Slurm 
* Improve znn so it doesn't waste computation when outz is not a divisor of the total ouput

