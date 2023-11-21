#!/bin/bash

# Calculate 30 minutes in seconds
delay_seconds=$((30 * 60))

# Schedule the script to run after a 30-minute delay
sleep $delay_seconds; ./scripts/submit_in_series.sh &

echo "The script has been scheduled to run in 30 minutes."

