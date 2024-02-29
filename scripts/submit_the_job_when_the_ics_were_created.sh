#!/bin/bash

# Directory to monitor
DIR="./ICs"

# Loop indefinitely until the condition is met
while true; do
  # Find files with '12' in their names and non-zero size in the directory
  # Count the number of such files
  COUNT=$(find "$DIR" -type f -name '*ref12*' -size +0c | wc -l)

  # Check if the count is 3 or more
  if [ "$COUNT" -ge 3 ]; then
    echo "Found 3 or more files with '12' in their names and non-zero size in $DIR"
    # Execute the compile_autosub.sh script
    ./compile_autosub.sh
    ./scripts/performance_report.sh &
    # Exit the script after execution
    exit 0
  else
    echo "Waiting for at least 3 files with '12' in their names and non-zero size to be present in $DIR..."
    # Sleep for a specified amount of time before checking again
    sleep 5
  fi
done

