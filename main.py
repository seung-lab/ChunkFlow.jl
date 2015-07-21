#!/usr/bin/env python
__doc__ = """
run the whole pipeline from raw data to omni projects

Jingpeng Wu <jingpeng.wu@gmail.com>, 2015
"""
import time
import os
from global_vars import *

#%% watershed chop
from watershed.watershed_chop import watershed_chop
print "chopping volume for watershed ..."
mstart = time.clock()
watershed_chop()
print "watershed chop time: {0:.2f}m".format( (time.clock()-mstart)/60 )

#%% run watershed
print 'run watershed... '
mstart = time.clock()
os.system(gws_bin_file + " --filename=" + gtmp + "/ws "\
            + "--high={} --low={} --dust={} --dust_low={} --threads={}".format(gws_high, gws_low, gws_dust, gws_dust_low, gws_threads_num))
print "watershed time: {0:.2f}m".format( (time.clock()-mstart)/60 )

#%% watershed merge
from watershed.watershed_merge import watershed_merge
print "merging chunks ..."
mstart = time.clock()
watershed_merge()
print "watershed merge time: {0:.2f}m".format( (time.clock()-mstart)/60 )

#%% omnify chop
from omnify.omnify_chop import omnify_chop
print "chopping volume to build small omni projects..."
mstart = time.clock()
omnify_chop()
print "omnify chop time: {0:.2f}m".format( (time.clock() - mstart)/60 )

#%% start meshing, Note that this part could also be parallized in AWS SGE by qsub the runall.sh
from global_vars import gom_data_path
print "omnification ..."
mstart = time.clock()
os.system("cd " + gom_data_path)
os.system("sh " + gom_data_path + "/runall.sh")
print "omnification takes {0:.2f}m".format( (time.clock() - mstart)/60 )

# move the omnify projects to S3
if "s3" in gznn_chann_origin:
    os.system("aws s3 cp "+ gom_projects_path + " " + gom_s3_prj)
