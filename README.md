AWS-ZNN
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



TODO list
===================
1. Improve documentation pipeline, there were many bugs primarily because ZNN assumes column-major, and python uses row-major order.
2. Make use of the scratch space provided in each node.
3. Evaluate moving from SGE to Slurm 
4. Add omnifycation and watershed to the scheduler with the right dependencies 
5. Remove files from earlier stages of the pipeline while processing the following stages to free space.





