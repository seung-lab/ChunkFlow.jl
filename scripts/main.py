# -*- coding: utf-8 -*-
"""
Created on Thu Apr 16 14:53:12 2015

run the watershed pipeline

@author: jingpeng
"""
import time
import os
from global_vars import *
#%% run znn chop and merge


#%% watershed chop
from watershed_chop import watershed_chop
print "chopping volume for watershed ..."
start = time.clock()
# watershed_chop()
print "watershed chop time: {0:.1f}m".format( (time.clock()-start)/60 )

#%% run watershed
print 'run watershed... '
start = time.clock()
os.system(gws_bin_file + " --filename=" + gtemp_file + "input "\
            + "--high={} --low={} --dust={} --dust_low={} --threads={}".format(gws_high, gws_low, gws_dust, gws_dust_low, gws_threads_num))
print "watershed time: {0:.1f}m".format( (time.clock()-start)/60 )

#%% watershed merge
from watershed_merge import watershed_merge
print "merging chunks ..."
start = time.clock()
watershed_merge()
print "watershed merge time: {0:.1f}m".format( (time.clock()-start)/60 )

#%% directly omnify the whole image stack
start = time.clock()
os.system("cd /data/jingpeng/")
os.system("sh /data/jingpeng/omnify.sh")
print "omnification time: {0:.1f}m".format( (time.clock()-start)/60 )

#%% omnify chop
from omnify_chop import omnify_chop
print "chopping volume to build small omni projects..."
start = time.clock()
# omnify_chop()
print "omnify chop time: {0:.1f}m".format( (time.clock() - start)/60 )

#%% start meshing
from global_vars import gomnify_data_file
print "omnification ..."
start = time.clock()
os.system("cd "+gomnify_data_file)
# os.system("sh " + gomnify_data_file + "run_all.sh")
print "omnification takes {0:.1f}m".format( (time.clock() - start)/60 )
