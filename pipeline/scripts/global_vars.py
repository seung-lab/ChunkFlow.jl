import numpy as np

#number of nodes available
max_nodes = 10

#Set the resources for the machine in which znn ,watershed and omnify will be run
memory = 20 * 10**9#gb
threads = 8

# We will apply two neural networks (stage1 and stage2)
# We need to know the field of view of each stage, and the "effective" field of view
# i.e. the FoV combined of both stages: z,y,x
fov_stage1 = np.array([1,109,109])
fov_stage2 = np.array([9,65,65])
fov_effective = np.array([9,173,173])

#%% basic
# note that we'd better put the channel and affinity data in local disk since it is IO bound.
#gchann_file = '../../../Ignacio/w0-4/omnify/channel.hdf5'
gchann_file = '/data/jingpeng/channel3.hdf5'
gaffin_file = '/data/jingpeng/znn_merged.hdf5'
gtemp_file = '/data/jingpeng/temp/'

# the path of omnify binary
gomnifybin = 'bash /data/jingpeng/omnify/omnify.sh'

#%% watershed chop
# step: z,y,x
gwidth = np.array([650, 647, 647], dtype='uint32')
# watershed parameters
gws_bin_file = '../watershed/src/quta/zi/watershed/main/bin/xxlws'
gws_high = 0.91
gws_low = 0.3
gws_dust = 400
gws_dust_low = 0.25
# if there are watershed error, we can try to change the threads number to 1
gws_threads_num = 4

#%% watershed merge
gws_merge_h5 = gtemp_file + "pywsmerge.Th-{}.Tl-{}.Ts-{}.Te-{}.h5".format(int(gws_high*1000), int(gws_low*1000), int(gws_dust), int(gws_dust_low*1000))

#%% omnify chop
# the block size and overlap size, z,y,x
gblocksize = np.array([128, 512, 512], dtype='uint32')
goverlap = np.array([20,32,32], dtype='uint32')
# voxel size: z,y,x
gvoxel_size = np.array([40,7,7])

# prepare the omnify data for omnifying
gomnify_data_file = '../omnify/'

# the save path of omni projects, should be local. Remote path may make the segmentation empty.
gomniprojects_save_file = '/data/jingpeng/omni_projects/'
