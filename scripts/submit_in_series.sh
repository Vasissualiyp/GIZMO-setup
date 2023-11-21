#!/bin/bash

systemname=$(hostname)
sleeptime=5 # Sleep time in sec

update_nodes() { #{{{ Update the number of nodes. Works on Niagara.
    local new_nodes="$1" # The new number of nodes
    local file_path="./template/run.sh" # Path to your SLURM script

    # Check if the file exists
    if [[ ! -f "$file_path" ]]; then
        echo "Error: File does not exist."
        return 1
    fi

    # Update the number of nodes using sed
    sed -i "s/#SBATCH --nodes=[0-9]*/#SBATCH --nodes=${new_nodes}/" "$file_path"
} #}}}

get_nodes() { #{{{
    local file_path="./nodenumbers.txt"

    # Check if the file exists and is not empty
    if [[ ! -s "$file_path" ]]; then
        echo "No more integers left in the file. Exiting the script."
        exit 0
    fi

    # Read the first line (the first integer) and store it in a variable
    read -r nodes_number < "$file_path"
    echo "$nodes_number"

    # Remove the first line from the file
    sed -i '1d' "$file_path"
} #}}}


main() { #{{{
while true; do
	if [[ "$systemname" == "nia-login"*".scinet.local" ]]; then # Niagara
		#clear
	        # Collect command output to a variable
	        output=$(sqc -u $USER)
	        # Calculate number of lines in the output
	        lines=$(echo "$output" | wc -l)
	        # Adjust the number of lines
	        lines=$((lines-1))
	
	else # Sunnyvale
		#sleeptime=$sleeptime * 10
	        # Collect command output to a variable
		clear
	        output=$(qstat -u $USER)
	        # Calculate number of lines in the output
	        lines=$(echo "$output" | wc -l)
	
	fi

	if [[ $lines -lt 1 ]]; then
	    nodes_number=$(get_nodes)   # Get the number of nodes from the file
	    update_nodes "$nodes_number"  # Update the number of nodes in run.sh

	    ./compile_autosub.sh
	fi

        sleep $sleeptime 
done	 
} #}}}

main
