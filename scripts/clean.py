import os
import shutil
from global_vars import *

#%% clean, remove the temporary files
shutil.rmtree( gtemp_file )
shutil.rmtree( gznn_tmp )

os.remove( gznn_batch_script_name )