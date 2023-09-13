#!/bin/bash
nohup bash -c "
function run_qstat {
  if ! command -v qstat &> /dev/null; then
    echo 'Please ssh to ricky to run this script'
    exit 1
  fi

  while true; do
    data=\$(qstat -u \$USER | awk 'NR > 5 {split(\$1, a, \".\"); print a[1] \" \" \$NF}')
    readarray -t lines <<<\"\$data\"

    if [ \"\${#lines[@]}\" -eq 0 ]; then
      ./compile_autosub.sh
      break
    fi

    sleep 60  # Wait for 60 seconds before checking again
  done
}

run_qstat
" > nohup_job_scheduler.out 2>&1 &


# Call the function with nohup and run it in the background
#nohup bash -c "run_qstat" > nohup.out 2>&1 &

