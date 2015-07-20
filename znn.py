#!/usr/bin/env python
__doc__ = """
run the whole pipeline from raw data to omni projects

Jingpeng Wu <jingpeng.wu@gmail.com>, 2015
"""
import time
import subprocess
from global_vars import *

#%% run parallel znn forward
from znn_forward.znn_chop import znn_chop
znn_chop()
#subprocess.call('qsub -V -b y -cwd '+ gznn_batch_script_name )
subprocess.call(['sh', gznn_batch_script_name])
from znn_forward.znn_merge import znn_merge
znn_merge()

