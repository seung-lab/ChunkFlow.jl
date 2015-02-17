[PATH]
config=./cluster/network_spec/VeryDeep2_w109.spec
load=./cluster/network_instance/VeryDeep2_w109/
data=./cluster/data/x0-y1/data_spec/stage1.
save=./cluster/data/x0-y1/output/

[OPTIMIZE]
n_threads=32
force_fft=1
optimize_fft=0

[TRAIN]
test_range=1
outsz=195,195,1
softmax=1

[MONITOR]
check_freq=10
test_freq=100

[SCAN]
outname=stage1