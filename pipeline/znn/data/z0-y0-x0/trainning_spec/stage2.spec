[PATH]
config=../znn/network_spec/VeryDeep2HR_w65x9.spec
load=../znn/network_instance/VeryDeep2HR_w65x9/
data=../znn/data/z0-y0-x0/data_spec/stage2.
save=../znn/data/z0-y0-x0/output/

[OPTIMIZE]
n_threads=8
force_fft=1
optimize_fft=0

[TRAIN]
test_range=1
outsz=47,43,3
softmax=0

[MONITOR]
check_freq=10
test_freq=100

[SCAN]
outname=stage2