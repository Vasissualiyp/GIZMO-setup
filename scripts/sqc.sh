#!/bin/bash

systemname=$(hostname)
sleeptime=1
# Move the cursor 1 line down
echo -e "\033[1B"

if [[ "$systemname" == "nia-login"*".scinet.local" ]]; then # Niagara
	while true; do
		  echo -ne "\033[2A" # Move the cursor to the beginning of the line
		    sqc -u $USER
		      sleep $sleeptime # Adjust the sleep duration (in seconds) based on how often you want to update the list
	      done
else # Sunnyvale
	 while true; do 
	        echo -ne "\033[2A" # Move the cursor to the beginning of the line
		qstat -u $USER 
		sleep $sleeptime 
	done	
fi
