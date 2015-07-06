import numpy as np

#%% basic
graw_chann_fname = "../omnify/raw_chann.92.h5"

# note that we'd better put the channel and affinity data in local disk since it is IO bound.
gchann_file = '../omnify/chann_batch92.h5'
gaffin_file = '../omnify/affin_batch92.h5'
gtemp_file = 'temp/'



#%% parameters for znn
#number of nodes available
max_nodes = 10

#Set the resources for the machine in which znn ,watershed and omnify will be run
memory = 20 * 10**9#gb
threads = 8

#%% znn forward
gznn_batch_script_name = "batch_znn_forward.sh"
gznn_znnpath = "/usr/people/jingpeng/seungmount/research/Jingpeng/01_ZNN/znn-release/"
gznn_netname = "W59_C10_P3_D3"
gznn_fov = np.array([3,99,99])
gznn_blocksize = np.array([20,20,20])
gznn_bin = gznn_znnpath + "bin/znn"
gznn_net_fname = gznn_znnpath + "networks/" + gznn_netname + ".spec"
gznn_netpath = gznn_znnpath + "experiments/" + gznn_netname + "/network/"
gznn_tmp = "./znn_temp/"
gznn_threads = 7
gznn_outsz = np.array([ 1, 100, 100 ])

#%% convert znn output to hdf5 file
fname = gznn_znnpath + "experiments/W59_C10_P3_D3/output/out92."
gnet_out_fnames = (fname+"0", fname+"1", fname+"2")
gchann_fname = gznn_znnpath + "dataset/fish/data/batch92.image"

#%% watershed chop
# step: z,y,x
gwidth = np.array([2000, 2000, 2000], dtype='uint32')
# watershed parameters
gws_bin_file = '../watershed/src/quta/zi/watershed/main/bin/xxlws'
gws_high = 0.92
gws_low = 0.3
gws_dust = 400
gws_dust_low = 0.25
# if there are watershed error, we can try to change the threads number to 1
gws_threads_num = 1


# prepare the omnify data for omnifying
gomnify_data_file = '../omnify/'

#%% watershed merge
gws_merge_h5 = gomnify_data_file + "pywsmerge.Th-{}.Tl-{}.Ts-{}.Te-{}.h5".format(int(gws_high*1000), int(gws_low*1000), int(gws_dust), int(gws_dust_low*1000))

#%% omnify chop
# the path of omnify binary
gomnifybin = 'bash ../omnify/omnify.sh'

# the block size and overlap size, z,y,x
gblocksize = np.array([2000, 2000, 2000], dtype='uint32')
goverlap = np.array([20,32,32], dtype='uint32')
# voxel size: z,y,x
gvoxel_size = np.array([45,5,5])

# the save path of omni projects, should be local. Remote path may make the segmentation empty.
# I get some error here and use full path solves the problem.
gomniprojects_save_file = '/usr/people/jingpeng/omni_projects/'
