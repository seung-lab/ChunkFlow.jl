#!/usr/bin/env python
__doc__ = """
run the whole pipeline from raw data to omni projects

Jingpeng Wu <jingpeng.wu@gmail.com>, 2015
"""
import time
import os
from global_vars import *
#%% run parallel znn forward
from aws_znn_forward.znn_chop import znn_chop
znn_chop()
#os.system('qsub -V -b y -cwd '+ gznn_batch_script_name )
os.system('sh '+ gznn_batch_script_name)
from aws_znn_forward.znn_merge import znn_merge
znn_merge()

