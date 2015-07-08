#!/bin/bash
export LD_LIBRARY_PATH=LD_LIBRARY_PATH:"/opt/boost/lib"
/usr/people/jingpeng/seungmount/research/Jingpeng/01_ZNN/znn-release/bin/znn --test_only=true --options="general.config"
    