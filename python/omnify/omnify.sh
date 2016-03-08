#!/bin/bash

export LD_PRELOAD="`ldconfig -p | grep libjemalloc.so | head -1 | cut -d'>' -f2 | cut -c2-`"
$(dirname "${BASH_SOURCE[0]}")/bin/omni.omnify "$@"

