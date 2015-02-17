[PATH]
config=./cluster/network_spec/VeryDeep2HR_w65x9.spec
load=./cluster/network_instance/VeryDeep2HR_w65x9/
data=./cluster/data/x0-y0/data_spec/stage2.1.spec
save=./cluster/data/x0-y0/output/

[OPTIMIZE]
n_threads=32
force_fft=1
optimize_fft=0

[TRAIN]
test_range=1
outsz=[desired output patch size] ??
softmax=1

[MONITOR]
check_freq=10
test_freq=100

[SCAN]
outname=stage2