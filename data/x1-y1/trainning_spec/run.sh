#!/bin/bash
    ./znn-release/bin/znn --options=./cluster/data/x1-y1/trainning_spec/stage2.spec --test_only=1
    ./znn-release/bin/znn --options=./cluster/data/x1-y1/trainning_spec/stage1.spec --test_only=1
    