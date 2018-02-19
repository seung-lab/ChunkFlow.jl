#!/bin/bash

aws batch submit-job --cli-input-json file://jobs.json
