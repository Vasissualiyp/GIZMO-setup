#!/bin/bash

# Fetch the data from squeue
data=$(squeue -u $USER -o "%.18i %.10M" --noheader)

# Read into array
readarray -t lines <<<"$data"

# Display jobs to user
echo "Here are your currently running jobs:"
for i in "${!lines[@]}"; do
  echo "$((i+1)): ${lines[i]}"
done

# Ask user which jobs to cancel
echo "Enter the indices of jobs you want to cancel (e.g. 1,3-5):"
read indices

# Translate user input to array of job indices
IFS=', ' read -ra IDX <<< "$indices"
JOBS_TO_CANCEL=()
for i in "${IDX[@]}"; do
    if [[ $i == *"-"* ]]; then
        IFS='-' read -ra RANGE <<< "$i"
        JOBS_TO_CANCEL+=($(seq "${RANGE[0]}" "${RANGE[1]}"))
    else
        JOBS_TO_CANCEL+=("$i")
    fi
done

# Cancel the jobs
for i in "${JOBS_TO_CANCEL[@]}"; do
  JOBID=$(echo ${lines[$((i-1))]} | awk '{print $1}')
  scancel "$JOBID"
done

