spipe
=======

IMPORTANT: THIS PROJECT CONTAINS CONFINDENTIAL INFORMATION
* It includes the credentials required to launch instances
* It contains a trained ZNN.


This project is intended to have all the logic required to:

1.  Launch a cluster in Amazon Web Services using spot instances (the ones where you bid to have access to the resources).
2.  Chop an stack of microscopy images with an specified overlap.
3.  Run ZNN in each chunk using all the nodes of the cluster, rerunning in another node if any node get out of service.
4.  Merge the ZNN output back in one file (znn_merged.hdf5)
5.  Chop the merged ZNN output to run parallel(thread) watershed (only in node for having consistent watershed, also because the disk I/O is the bottleneck)
6.  Merge the watershed chunks in one file (watershed_merged.hdf5)
7.  Chop the watershed merged output, and the microscopy images into many omni projects with a specified overlap, and omnify each project in one node.

Documentation:
 Each folder contains a markdown files, navigate through the tree reading them.
 Read also in-code comments
 Last modification was in March 18, 2015.



 alignment/ should contain all aligned tif images, which shouldn't have applied any filter ( unless the znn was trained with that filter)

 znn/ , watershed/ , and omnify/ contains the source code and/or binaries required to run. They all contain a data/ folder which contains the chunks  to be processed, this chunks are create by the python scrips in /scripts.

 /trace contains the finished omni projects, which should be download.


TODO list
===================
1. Make use of the scratch space provided in each node.
2. Evaluate moving from SGE to Slurm
3. change znn to read/write chunk directly from/to hdf5 file to avoid choping and merging
