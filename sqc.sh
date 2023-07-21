#!/bin/bash

# Move the cursor 1 line down
echo -e "\033[1B"

while true; do
	  echo -ne "\033[2A" # Move the cursor to the beginning of the line
	    sqc -u $USER
	      sleep 1 # Adjust the sleep duration (in seconds) based on how often you want to update the list
      done

