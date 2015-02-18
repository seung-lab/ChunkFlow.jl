[PATH]
config=./network_spec/VeryDeep2HR_w65x9.spec
load=./network_instance/VeryDeep2HR_w65x9/
data=./data/x1-y1/data_spec/stage2.
save=./data/x1-y1/output/

[OPTIMIZE]
n_threads=32
force_fft=1
optimize_fft=0

[TRAIN]
test_range=1
outsz=40,40,5
softmax=1

[MONITOR]
check_freq=10
test_freq=100

[SCAN]
outname=stage2