cd ./znn-release/makecd ../qsub -V -b y -cwd ./data/x0-y0/trainning_spec/run.sh 
qsub -V -b y -cwd ./data/x0-y1/trainning_spec/run.sh 
qsub -V -b y -cwd ./data/x1-y0/trainning_spec/run.sh 
qsub -V -b y -cwd ./data/x1-y1/trainning_spec/run.sh 
