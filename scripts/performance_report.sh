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

last_redshift=0
while true; do
  clear
  
  # Get the current date in the required format
  current_date=$(date +"%Y.%m.%d")
  date_folder="./output/${current_date}:"

  # If the attempt number is provided, use it
  if [ -n "$1" ]; then
    attempt_number=$1
  else
    # If not provided, find the latest attempt number
    attempt_number=$(get_latest_attempt "${date_folder}")
  fi

  folder="${date_folder}${attempt_number}/"

  # Check if the folder exists
  if [ -d "${folder}" ]; then
    # Count the number of snapshots and subtract 1
    snapshot_count=$(ls "${folder}"snapshot_*.hdf5 2>/dev/null | wc -l)
    snapshot_count_minus_one=$((snapshot_count - 1))
    performance_file="${folder}performance_report.csv"

    # Obtain redshift
    scaling_factor=$(tail -n 35 output/2023.09.11\:1/cpu.txt | grep '^Step' | awk '{print $4}' | sed 's/.$//') 
    redshift=$(echo "1/$scaling_factor - 1" | bc -l)
    redshift=$(printf "%.2f\n" $redshift)
    
    echo "Current folder: ${folder}"
    echo "Number of snapshots: ${snapshot_count_minus_one}"
    echo "Current redshift: ${redshift}"
    if [ ! -f "$performance_file" ]; then
        touch "$performance_file"
        echo "time,redshift" >> "$performance_file"
    fi
    if [ "$redshift" != "$last_redshift" ]; then
        echo "$(date '+%s'),$redshift" >> "$performance_file"
	last_redshift=$redshift
    fi
        

    # Optionally, list the files in the folder
    # ls "${folder}"
  else
    echo "Folder ${folder} does not exist."
  fi

  sleep 2
done
