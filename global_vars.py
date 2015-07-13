import numpy as np

#%% basic
# note that we'd better put the channel and affinity data in local disk since it is IO bound.
# if we put them in remote mounted folder, the chopping could be slow due to IO latency
gchann_file = 'data/chann_batch92.h5'
gaffin_file = 'data/affin_batch92.h5'
gtemp_file = 'tmp/'

# voxel size: z,y,x
gvoxel_size = np.array([45,5,5])

#%% znn forward
gznn_batch_script_name = "batch_znn_forward.sh"
gznn_znnpath = "/usr/people/jingpeng/seungmount/research/Jingpeng/01_ZNN/znn-release/"
gznn_netname = "W5_C10_P3_D2"
gznn_fov = np.array([9,65,65])
gznn_blocksize = np.array([20,20,20])
gznn_bin = gznn_znnpath + "bin/znn"
gznn_net_fname = gznn_znnpath + "networks/" + gznn_netname + ".spec"
gznn_netpath = gznn_znnpath + "experiments/" + gznn_netname + "/network/"
gznn_tmp = "/mnt/"
gznn_threads = 7
gznn_outsz = np.array([ 1, 100, 100 ])
gznn_chann_fname = gznn_znnpath + "dataset/fish/data/batch92.image"

#%% watershed chop
# step: z,y,x
gws_width = np.array([2000, 2000, 2000], dtype='uint32')
# watershed parameters
gws_bin_file = './src/quta/zi/watershed/main/bin/xxlws'
gws_high = 0.92
gws_low = 0.3
gws_dust = 400
gws_dust_low = 0.25
# if there are watershed error, we can try to change the threads number to 1
gws_threads_num = 1

# prepare the omnify data for omnifying
gom_data_path = '../tmp/'

#%% watershed merge
gws_merge_h5 = gom_data_path + "pywsmerge.Th-{}.Tl-{}.Ts-{}.Te-{}.h5".format(int(gws_high*1000), int(gws_low*1000), int(gws_dust), int(gws_dust_low*1000))

#%% omnify chop
# the path of omnify binary
gom_bin = 'bash omnify.sh'
# the block size and overlap size, z,y,x
gom_blocksize = np.array([2000, 2000, 2000], dtype='uint32')
gom_overlap = np.array([20,32,32], dtype='uint32')

# the save path of omni projects, should be local. Remote path may make the segmentation empty.
# I get some error here and use full path solves the problem.
gom_projects_path = '/usr/people/jingpeng/omni_projects/'
