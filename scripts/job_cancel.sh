#!/bin/bash

systemname=$(hostname)

# function to process squeue for Niagara {{{
function run_squeue {
  echo "Here are your currently running jobs:"
  data=$(squeue -u $USER -o "%.18i %.10M" --noheader)
  readarray -t lines <<<"$data"

  for i in "${!lines[@]}"; do
    echo "$((i+1)): ${lines[i]}"
  done
}
#}}}

# function to process qstat for Sunnyvale {{{
function run_qstat {
  if ! command -v qstat &> /dev/null; then
    echo "Please ssh to ricky to run this script"
    exit 1
  fi
  echo "Here are your currently running jobs:"

  data=$(qstat -u $USER | awk 'NR > 5 {split($1, a, "."); print a[1] " " $NF}')
  readarray -t lines <<<"$data"

  for i in "${!lines[@]}"; do
    echo "$((i+1)): ${lines[i]}"
  done
}
#}}}

# function to cancel jobs {{{
function cancel_jobs {
  read indices
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

  for i in "${JOBS_TO_CANCEL[@]}"; do
    JOBID=$(echo ${lines[$((i-1))]} | awk '{print $1}')
    if [[ "$systemname" == "nia-login"*".scinet.local" ]]; then
      scancel "$JOBID"
    else
      qdel "$JOBID"
    fi
  done
}
#}}}

if [[ "$systemname" == "nia-login"*".scinet.local" ]]; then
  run_squeue
else
  run_qstat
fi

echo "Enter the indices of jobs you want to cancel (e.g. 1,3-5):"
cancel_jobs

