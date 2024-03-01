#!/bin/bash

# Function to find the latest attempt number if not provided
get_latest_attempt() {
  local date_folder="$1"
  latest_attempt=0
  for attempt in $(ls -d "${date_folder}"* 2>/dev/null); do
    attempt_number=${attempt##*:}
    if [[ $attempt_number -gt $latest_attempt ]]; then
      latest_attempt=$attempt_number
    fi
  done
  echo $latest_attempt
}

# Default values
report=true
specified_date=""
specified_attempt=""

# Parse arguments for target time
while [[ "$#" -gt 0 ]]; do
    case $1 in
        --date) specified_date="$2"; shift ;;
        --attempt) specified_attempt="$2"; shift ;;
        --noreport) report=false ;;
        --target-time) TARGET_TIME="$2"; shift ;;
    esac
    shift
done

# Validate TARGET_TIME is an integer and set a default if not
if ! [[ "$TARGET_TIME" =~ ^[0-9]+$ ]]; then
    TARGET_TIME=3600 # Default to 1 hour if TARGET_TIME is not an integer
fi

# Determine the current or specified date
current_date=$(date +"%Y.%m.%d")
if [[ -n "$specified_date" ]]; then
    current_date=$specified_date
fi

# Build the base directory path with the current or specified date
date_folder="./output/${current_date}:"

# Determine the attempt number
if [[ -n "$specified_attempt" ]]; then
    attempt_number=$specified_attempt
else
    # If not provided, find the latest attempt number
    attempt_number=$(get_latest_attempt "${date_folder}")
fi

folder="${date_folder}${attempt_number}/"

# Main loop
last_redshift=0
while [ "$SECONDS" -lt "$TARGET_TIME" ]; do
  clear

  # Check if the folder exists
  if [ -d "${folder}" ]; then
    # Count the number of snapshots and subtract 1
    snapshot_count=$(find "${folder}" -type f -name "snapshot_*.hdf5" -o -type d -name "snapdir_*" 2>/dev/null | wc -l)
    snapshot_count_minus_one=$((snapshot_count - 1))
    performance_file="${folder}performance_report.csv"

    # Obtain redshift from the CPU usage file
    cpu_usage_file="${folder}cpu.txt"
    scaling_factor=$(tail -n 35 $cpu_usage_file | grep '^Step' | awk '{print $4}' | sed 's/.$//')
    redshift=$(echo "1/$scaling_factor - 1" | bc -l)
    redshift_round=$(printf "%.2f\n" $redshift)
    scaling_factor_round=$(printf "%.5f\n" $scaling_factor)

    # Echo the current state of the sim
    echo "Current folder: ${folder}"
    echo "Number of snapshots: ${snapshot_count_minus_one}"
    echo "Current redshift: ${redshift_round}"
    echo "Current scaling factor: ${scaling_factor_round}"

    if $report; then
      # Save current time and redshift into the performance reporting csv file
      if [ ! -f "$performance_file" ]; then
          touch "$performance_file"
          echo "time,redshift" >> "$performance_file"
      fi
      if [ "$redshift" != "-1" ] && [ "$redshift" != "$last_redshift" ]; then
          echo "$(date '+%s'),$redshift" >> "$performance_file"
          last_redshift=$redshift
      fi
    fi
  else
    echo "Folder ${folder} does not exist."
  fi

  sleep 2
done

