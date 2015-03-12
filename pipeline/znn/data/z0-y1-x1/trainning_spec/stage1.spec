[PATH]
config=../znn/network_spec/VeryDeep2_w109.spec
load=../znn/network_instance/VeryDeep2_w109/
data=../znn/data/z0-y1-x1/data_spec/stage1.
save=../znn/data/z0-y1-x1/output/

[OPTIMIZE]
n_threads=8
force_fft=1
optimize_fft=0

[TRAIN]
test_range=1
outsz=128,178,1
softmax=1

[MONITOR]
check_freq=10
test_freq=100

[SCAN]
outname=stage1