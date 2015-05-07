StarCluster 
==========
copy aws-znn.pem to ~/.ssh/ in your workstation.
copy config to ~/.starcluster/config

run in a terminal:
starcluster -c smallcluster mycluster
this will launch the master node.

the instance type is application specific. Should check the available instance types before starting an instance.
http://aws.amazon.com/ec2/instance-types/

Modify the volume, the size of the volume should be about 20 times the size of the raw images.
firstly all tiff images are converted into an hdf5 file.
Also a channel stack which is a crop version of the original stack is created.
Then you have znn affinities which 3 times the size of the raw images.And there are two stages.
You also have znn_merged, which is again 3 times the size of the raw images.
The watershed chunks are 3X raw images.
watershed_merged is 1X raw images.
omni project chunks is 2x raw images.
omni project ready to be trace is 3x raw images.


To launch 10 workers node bidding 40 cents per hour per node do:
startcluster addnode mycluster -n 10 --bid 0.40

To remove and specific node:
startcluster removenode mycluster node002

to terminate the cluster:
starcluster terminate mycluster


