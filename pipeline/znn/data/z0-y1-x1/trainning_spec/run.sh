#!/bin/bash
		../znn/znn-release/bin/znn --options=../znn/data/z0-y1-x1/trainning_spec/stage1.spec --test_only=1
		../znn/znn-release/bin/znn --options=../znn/data/z0-y1-x1/trainning_spec/stage2.spec --test_only=1
		