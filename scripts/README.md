scripts folder
==============

After the master node is launched, we can start uploading the tiff images to AWS.
We have to specify how many nodes are available, and how much RAM and cores does each node have.
Then the first once should call is znn_chop.py, this will fill the znn/data/ with one folder for each chunk.
It will also create the /scripts/scheduleJobs.sh which should be run to schedule the jobs. After the jobs are schedule a first worker node can be launch, which will start processing the first chunk. We should verify the amount of RAM used is inside the limits, before launching all the other workers nodes.
Once all the chunks has been processed all the nodes can be shut down.
We can then execute znn_merge.py which will create /znn/data/znn_merged.hdf5

After that is done, we call watershed_chop.py to create chunks so that watershed can run in parallel(threads), which also calls the watershed binary.

Once watershed finishes, you have to call watershed_merge.py which will produce /watershed/data/watershed_merged.hdf5.

Lastly, you have to call omnify_chop.py you have to modify the "divs" variable, to specify how many omni projects you want, the overlap between projects can be also specify there.

This will create one folder for each chunk in omnify/data/ , each of this chunk will have a run.sh file which should be run to produce an omni project in /trace/

files
======
|file name|function|notes|
|:-------:|----------------------------------|-----------------------------------|
|stack.py|manging the data inside alignment, this include generating the channel data required for omnifying.||
|znn.py|generate the text file which specifies training and data for ZNN||
|znn_chop.py|chop the channel data and prepare for znn running||
|znn_merge.py|merge the znn output files||
|main.py|run all the watershed subpipeline to get files to prepare omnification|todo: include the znn and omnification sted and we only need to run main.py|
|watershed_chop.py|chop affinity data and prepare files for watershed and run watershed||
|watershed_merge.py|merge the watershed results (segment chunks) to get a hdf5 file||
|omnify_chop.py|chop the segment and channel hdf5 file to get overlaped chunks, and prepare the omnification cmd and shell files|just ```sh run_all.sh``` will automatically do omnification for all the omni projects|
|relabel.py|relabel the segment chunks from 1 to N|used in omnify_chop.py|
|c_relabel.pyx|cython code for relabel|speed up some functions in relabel.py|
|setup.py|compile the c_relabel.pyx to a .so library|use command in code|
|clean.py|delete all the temporal files|todo:delete the temporal watershed files|
