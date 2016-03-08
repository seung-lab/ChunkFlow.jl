#!/bin/bash

#compress everything in chunks of less than 100mb so it can be upload to github
tar czpvf - ./bin-uncompress | split -d -b 99M - bin-part-
