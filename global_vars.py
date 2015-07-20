import numpy as np
import os

# configure sys path
import sys
current_path = os.path.dirname(os.path.abspath(__file__))
if current_path not in sys.path:
    sys.path.append(current_path)

#%% basic
# global temporary folder for whole pipeline
gabspath = os.path.dirname(os.path.abspath(__file__)) + "/"
# temporary folder in local node 
gtmp = '/tmp/spipe/'

# note that we'd better put the channel and affinity data in local disk since it is IO bound.
# if we put them in remote mounted folder, the chopping could be slow due to IO latency
gchann_file = gtmp + 'chann.h5'
gaffin_file = gtmp + 'affin.h5'

# voxel size: z,y,x
gvoxel_size = np.array([45,5,5])

#%% znn forward
gznn = "/usr/people/jingpeng/seungmount/research/Jingpeng/01_ZNN/znn-release/"
#gznn_chann_origin = "s3://zfish/fish-train/Merlin_raw2.tif"
gznn_chann_origin = "/usr/people/jingpeng/seungmount/research/Jingpeng/13_zfish/fish_train/Merlin_raw2.tif"
gznn_raw_chann_fname = gtmp + "raw_chann.h5"
# networks
gznn_net_names = ("W5_C10_P3_D2","VeryDeep2HR_w65x9")
# field of view, (z,y,x)
gznn_fovs = ( np.array([1,99,99]), np.array([9,65,65]) )
# output affinity block size for each node
gznn_blocksize = np.array([20,50,50])
gznn_bin = gznn + "bin/znn"
gznn_batch_script_name = gtmp + "znn_batch_forward.sh"
# boost lib path for running znn. setting this in case boost is not in system path
gznn_boost_lib = "/opt/boost/lib"
# temporary folder for znn, this folder should be unique for every node in AWS
# in EC2 instance, the '/mnt' is a local cache partition.
gznn_tmp = "/tmp/znn_tmp/"
gznn_threads = 7
# output size of each epoch
gznn_outsz = np.array([ 3, 60, 60 ])

#%% watershed chop
# step: z,y,x
gws_width = np.array([2000, 2000, 2000], dtype='uint32')
# watershed parameters
gws_bin_file = gabspath + 'watershed/src/quta/zi/watershed/main/bin/xxlws'
gws_high = 0.999
gws_low = 0.3
gws_dust = 400
gws_dust_low = 0.25
# if there are watershed error, we can try to change the threads number to 1
gws_threads_num = 1
#%% watershed merge
gws_merge_h5 = gtmp + "pywsmerge.Th-{}.Tl-{}.Ts-{}.Te-{}.h5".format(int(gws_high*1000), int(gws_low*1000), int(gws_dust), int(gws_dust_low*1000))

#%% omnify chop
# prepare the omnify data for omnifying
gom_data_path = gtmp
# the path of omnify binary
gom_bin = 'bash ' + gabspath + 'omnify/omnify.sh'
# the block size and overlap size, z,y,x
gom_blocksize = np.array([2000, 2000, 2000], dtype='uint32')
gom_overlap = np.array([20,32,32], dtype='uint32')

# the save path of omni projects, should be local. Remote path may make the segmentation empty.
# I get some error here and use full path solves the problem.
gom_projects_path = gtmp + 'ompro/'
# the S3 bucket directory
#gom_s3_prj = "https://s3.amazonaws.com/zfish/om_prj/"

#%% evaluate
