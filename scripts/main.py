# -*- coding: utf-8 -*-
"""
Created on Thu Apr 16 14:53:12 2015

run the watershed pipeline

@author: jingpeng
"""
import time

#%% run znn chop and merge


#%% watershed chop
from watershed_chop import watershed_chop
print "chopping volume for watershed ..."
start = time.clock()
#watershed_chop()
print "watershed chop time: {0:.1f}".format(time.clock()-start)

#%% watershed merge
from watershed_merge import watershed_merge
print "merging chunks ..."
start = time.clock()
#watershed_merge()
print "watershed merge time: {0:.1f}".format(time.clock()-start)

#%% omnify chop
from omnify_chop import omnify_chop
print "chopping volume to build small omni projects..."
start = time.clock()
omnify_chop()
print "omnify chop time: {0:.1f}".format(time.clock() - start)

#%% start meshing
from global_vars import gomnify_data_file
import os
print "omnification ..."
start = time.clock()
os.system("cd "+gomnify_data_file)
os.system("sh " + gomnify_data_file + "run_all.sh")
print "omnification takes {0:.1f}m".format( (time.clock() - start)/60 )
