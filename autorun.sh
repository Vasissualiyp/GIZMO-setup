#!/bin/bash
#This script automatically submits the job and edits all the necessary conditions for the files.

SERVER=gleb@weisskoffer.servehttp.com
PORT=2240

# Get today's date
TODAY=$(date +"%Y/%m/%d")
TODAY_FORMAT=$(date +"%Y-%m-%d")

# open the run.sh file in vim
vim run.sh <<- EOF
  6G
  17l
  d$
  :wq
EOF
#
## Submit the job
#sbatch run.sh
#
## Get the job number of the submitted simulation
#JOB_NUMBER=$(echo $(sqc -u $USER | tail -n 1 | awk '{print $1}'))
#
#echo $JOB_NUMBER
