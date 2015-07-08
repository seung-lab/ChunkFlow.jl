[INPUT]
size=1

[INPUT_C1]
size=3,3,1
init_type=normalized

[C1]
size=40
activation=relu

[C1_C2]
size=2,2,1
init_type=normalized

[C2]
size=40
activation=relu
filter=max
filter_size=2,2,1
filter_stride=2,2,1

[C2_C3]
size=3,3,1
init_type=normalized

[C3]
size=40
activation=relu

[C3_C4]
size=3,3,1
init_type=normalized

[C4]
size=40
activation=relu
filter=max
filter_size=2,2,1
filter_stride=2,2,1

[C4_C5]
size=3,3,1
init_type=normalized

[C5]
size=40
activation=relu

[C5_C6]
size=3,3,1
init_type=normalized

[C6]
size=50
activation=relu

[C6_C7]
size=3,3,1
init_type=normalized

[C7]
size=50
activation=relu

[C7_C8]
size=3,3,1
init_type=normalized

[C8]
size=50
activation=relu
filter=max
filter_size=2,2,1
filter_stride=2,2,1

[C8_C9]
size=3,3,1
init_type=normalized

[C9]
size=60
activation=relu

[C9_C10]
size=3,3,1
init_type=normalized

[C10]
size=60
activation=relu

[C10_FC]
size=3,3,3
init_type=normalized

[FC]
size=200
activation=relu

[FC_OUTPUT]
init_type=normalized
size=1,1,1

[OUTPUT]
size=3
activation=forward_logistic
