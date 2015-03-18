scripts folder
==============

After the master node is launched, we can start uploading the tiff images to AWS.
We have to specify how many nodes are available, and how much RAM and cores does each node have.
Then the first once should call is znn_chop.py, this will fill the znn/data/ with one folder for each chunk. 
It will also create the /scripts/scheduleJobs.sh which should be run to schedule the jobs. After the jobs are schedule a first worker node can be launch, which will start processing the first chunk. We should verify the amount of RAM used is inside the limits, before launching all the other workers nodes.
Once all the chunks has been processed all the nodes can be shut down.
We can then execute znn_merge.py which will create /znn/data/znn_merged.hdf5
After that is done, we call watershed_chop.py to create chunks so that watershed can run in parallel(threads), which also calls the watershed binary.If you want to change the watershed parameters you have to modify the last line of this script.
Once watershed finishes, you have to call watershed_merge.py which will produce /watershed/data/watershed_merged.hdf5.
Lastly, you have to call omnify_chop.py you have to modify the "divs" variable, to specify how many omni projects you want, the overlap between projects can be also specify there.
This will create one folder for each chunk in omnify/data/ , each of this chunk will have a run.sh file which should be run to produce an omni project in /trace/

stack.py is a module responsible of manging the data inside alignment, this include generating the channel data required for omnifying.
znn.py is a module with utile methods for generate the text file which specifies training and data for ZNN.

