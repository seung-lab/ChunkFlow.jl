aws
===
this script can create a "persistent" spot instance. After required a spot instance, it will continuously monitor this instance. Once this spot instance got terminated, it will create a new spot instance request.

Note that only one znn training instance in each cluster. For different training case, you have to change the cmd in runznn plugin and the cluster tag in the main script.

##Setup

* [install starcluster](http://star.mit.edu/cluster/docs/latest/installation.html). `easy_install StarCluster`
* download [StarCluster](https://github.com/jtriley/StarCluster) and set the StarCluster folder as a PYTHONPATH.
  * ``git clone https://github.com/jtriley/StarCluster.git``
  * put this line `export PYTHONPATH=$PYTHONPATH:"/path/to/StarCluster"` to the end of `~/.bashrc` file.
  * run `source ~/.bashrc`
* edit and move `config` file to `~/.starcluster/`.
  * setup the keys in `config`.
  * set the AMI and volume id.
  * setup all the parameters with a mark of `XXX`

##Tutorial
to run a program, you have to set some additional parameters.
* set the instance type in `config`
* set the spot biding in main script.
* run the main script: `python persistent_spot_cluster.py`
