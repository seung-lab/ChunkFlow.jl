[PATH]
config=[/path/to/network_spec/]VeryDeep2HR_w65x9.spec
load=[/path/to/network_instance/]VeryDeep2HR_w65x9/
data=[/path/to/data_spec/]stage2.
save=[/path/to/save/stage2/output/]

[OPTIMIZE]
n_threads=32
force_fft=1
optimize_fft=0

[TRAIN]
test_range=1
outsz=[desired output patch size]
softmax=1

[MONITOR]
check_freq=10
test_freq=100

[SCAN]
outname=[desired output file name]