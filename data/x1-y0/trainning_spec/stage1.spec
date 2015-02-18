[PATH]
config=./network_spec/VeryDeep2_w109.spec
load=./network_instance/VeryDeep2_w109/
data=./data/x1-y0/data_spec/stage1.
save=./data/x1-y0/output/

[OPTIMIZE]
n_threads=32
force_fft=1
optimize_fft=0

[TRAIN]
test_range=1
outsz=32,32,1
softmax=1

[MONITOR]
check_freq=10
test_freq=100

[SCAN]
outname=stage1