import os
from os.path import isfile
import shutil
import os, errno

def silentremove(filename):
    try:
        os.remove(filename)
    except OSError as e: # this would be "except OSError, e:" before Python 2.6
        if e.errno != errno.ENOENT: # errno.ENOENT = no such file or directory
            raise # re-raise exception if a different error occured

def silentremovedir(filedir):
    
	shutil.rmtree(filedir,ignore_errors=True)
	return

for chunk_dir in os.listdir('../data/'):
  	
	#Get max chunk size in voxels
	fname0 = '../data/{0}/output/stage21.0.size'.format(chunk_dir)
	fname1 = '../data/{0}/output/stage21.1.size'.format(chunk_dir)	
	fname2 = '../data/{0}/output/stage21.2.size'.format(chunk_dir)
	if isfile(fname0) and isfile(fname1) and isfile(fname2): 	
		print 'starcluster get mycluster /home/aws-znn/aws-upload/data/{0}/output/ ~/seungmount/research/Ignacio/w0-4/znn-output/{0}/ \n'.format(chunk_dir)

		silentremove('../data/{0}/output/stage11.0'.format(chunk_dir))
                silentremove('../data/{0}/output/stage11.0.size'.format(chunk_dir))
                silentremove('../data/{0}/output/stage11.1'.format(chunk_dir))
                silentremove('../data/{0}/output/stage11.1.size'.format(chunk_dir))
		silentremovedir('../data/{0}/input/'.format(chunk_dir))
	else:
		print Exception("echo 'There is no stage 2 output in chunk {0}'".format(chunk_dir))
