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
* Modify stack.py to work with the file organization of tommy, to work with an stack that doesn't fit in ram
* find src code of watershed, and write watershed.py to merge the output of znn, and convert it to hdf5 , so the watershed binaries can process it.Again, all this has to be done with loading the hole thing in ram.
* omnify folder should either hold the src code of a version of omni with headless support, or the libraries requiered to be preloaded when running omni. omnify.py should have the logic (if requiered) to crop the hdf5 watershed output, and submit the jobs so this can be run parallely. Also it should write an script to rsync the omni(s) project back to princeton. (Do we want to also download other data back?)