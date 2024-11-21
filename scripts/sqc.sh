#!/bin/bash

systemname=$(hostname)
sleeptime=1

# Move the cursor 1 line down
echo -e "\033[1B"

if [[ "$systemname" == "nia-login"*".scinet.local" ]]; then # Niagara
    watch -n $sleeptime sqc -u "$USER"
else # Sunnyvale
    sleeptime=$sleeptime * 10
    watch -n $sleeptime qstat -u "$USER"
fi

