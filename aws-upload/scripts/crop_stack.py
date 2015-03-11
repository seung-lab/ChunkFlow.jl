import h5py
infile = h5py.File('/usr/people/it2/seungmount/research/Ignacio/w0-4/omnify/stack_W1234.chann.hdf5', 'r')
chann_in = infile['/main']
print 'running'
out =  h5py.File('/usr/people/it2/seungmount/research/Ignacio/w0-4/omnify/stack_test.chann.hdf5', 'w')
chann_out = out.create_dataset('/main', data=chann_in[4:64+4,86:1142+86,86:1370+86])



infile.close()
out.close()