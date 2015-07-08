#!/usr/bin/python
from starcluster import config
import time
import threading

#%% parameters
conf_file = "~/.starcluster/config"

# cluster tag or name
tag = 'jingpeng3'

# mount volume id
volume_id = 'vol-1f5367f1'

# your bidding of spot instance
spot_bid = 0.41

# command
cmd = 'cd /home/znn-release/; sh znn_train.sh'

# instance type
instance_type = 'c3.8xlarge'

# since we want to run 1 master node as spot, so set it True.
# set false for test and we will start a on-demand master node.
force_spot_master = True 

# if there are several cluster template in config file, you have to set the cluster id to a specific cluster template
cluster_id = 0

# sleep interval (secs)
sleep_interval = 1 * 60

#%% configuration
cfg = config.get_config( conf_file )
cl = cfg.get_clusters()[ cluster_id ]
cl.spot_bid = spot_bid
cl.cluster_tag = tag
cl.force_spot_master = force_spot_master
cl.volumes['data']['volume_id'] = volume_id
cl.node_instance_type = instance_type

#%% a thread to run
class ThreadRun(object):
    def __init__(self, cl):
        self.cl = cl
        thread = threading.Thread(target=self.run, args=())
        thread.daemon = True                            # Daemonize thread
        thread.start()                                  # Start the execution
    def run(self):
        """ Method that runs forever """
        self.cl.start()
        cl.wait_for_cluster(msg='Waiting for cluster to come up...')

#%% plugin
from starcluster.clustersetup import ClusterSetup
class RunZnn(ClusterSetup):
    def __init__(self, cmd):
        self._cmd = cmd
    def run(self, nodes, master, user, user_shell, volumes):
        master.ssh.execute( self._cmd )

rz = RunZnn( cmd )

#%% start the cluster
print "constantly check whether this cluster is stopped or terminated."
cid = 0
while True:
    if (not cl.nodes) or cl.is_cluster_stopped() or cl.is_cluster_terminated():
        cid = cid + 1
        f = open('log.txt','a+')
        f.write( "try to start a cluster with id: {}\n".format( cid ) )
        print "try to start a cluster with id: {}\n".format( cid )
        time.sleep(1)

        # run the start in a separate thread
        try:
            threadRun = ThreadRun(cl)
            print "clulster creater thread running..."
            # wait for the volume mounted
            print "wait for the volume to attach..."
            vol_id = cl.volumes['data']['volume_id']
            volume = cl.ec2.get_volume( vol_id )
            cl.ec2.wait_for_volume( volume, state='attached' )
            
            print "run plugin"
            time.sleep(1*60)
            cl.run_plugin(rz)
        except:
            print "running failed"
            time.sleep(1)
            pass

        f.write('wait for cluster...\n')
        time.sleep(1)

        f.close()
    # sleep for a while
    print "cluster is running, wait for {} secs to check.".format( sleep_interval )
    time.sleep( sleep_interval )
