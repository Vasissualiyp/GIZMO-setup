#!/bin/bash

systemname=$(hostname)
sleeptime=1

# Move the cursor 1 line down
echo -e "\033[1B"

if [[ "$systemname" == "nia-login"*".scinet.local" ]]; then # Niagara
	while true; do
		#clear
                # Collect command output to a variable
                output=$(sqc -u $USER)
                # Calculate number of lines in the output
                lines=$(echo "$output" | wc -l)
                # Adjust the number of lines
                lines=$((lines-2))

                # Move the cursor to the beginning of the line
                echo -ne "\033[2A"

                # Print command output
                echo "$output"

                # Move the cursor up by number of lines in the output
                if [ $lines -gt 0 ]; then
                    tput cuu $lines
                fi

                sleep $sleeptime # Adjust the sleep duration (in seconds) based on how often you want to update the list
	done
else # Sunnyvale
	while true; do
		sleeptime=$sleeptime * 10
                # Collect command output to a variable
		clear
                output=$(qstat -u $USER)
                # Calculate number of lines in the output
                lines=$(echo "$output" | wc -l)
                # Adjust the number of lines
                lines=$((lines-2))

                # Move the cursor to the beginning of the line
                #echo -ne "\033[2A"

                # Print command output
                echo "$output"

                # Move the cursor up by number of lines in the output
                #if [ $lines -gt 0 ]; then
                #    tput cuu $lines
                #fi

                sleep $sleeptime 
	done	
fi

