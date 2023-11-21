#!/bin/bash

systemname=$(hostname)
sleeptime=5 # Sleep time in sec

change_number_of_processes_starq() { #{{{
    local file_path="./template/run-starq.sh" # Path to your SLURM script
    
    # Extract ppn value
    ppn=$(awk -F 'nodes=|:ppn=' '/#PBS -l nodes=/ {print $3}' "$file_path")
    #echo "$ppn"
    
    # Extract OMP_NUM_THREADS value
    openmp_threads=$(grep -Po '(?<=export OMP_NUM_THREADS=)\d+' "$file_path")
    #echo "$openmp_threads"
    
    # Your new node count
    local new_nodes="$1" # The new number of nodes
    #echo "$new_nodes"
    
    # Calculate new number of processes
    new_processes=$((new_nodes * ppn / openmp_threads))
    #echo "$new_processes"
    
    # Replace the number of processes in the mpirun command
    sed -i "/^mpirun -np [0-9]* -map-by node:SPAN/c\mpirun -np $new_processes -map-by node:SPAN ./gizmo/GIZMO zel.params > output.log" "$file_path"
} #}}}

update_nodes() { #{{{ Update the number of nodes. Works on Niagara.
    local new_nodes="$1" # The new number of nodes
    if [[ "$systemname" == "nia-login"*".scinet.local" ]]; then # Niagara
        local file_path="./template/run.sh" # Path to your SLURM script
    else # Sunnyvale
        local file_path="./template/run-starq.sh" # Path to your SLURM script
    fi

    # Check if the file exists
    if [[ ! -f "$file_path" ]]; then
        echo "Error: File does not exist."
        return 1
    fi

    # Update the number of nodes using sed
    if [[ "$systemname" == "nia-login"*".scinet.local" ]]; then # Niagara
        sed -i "s/#SBATCH --nodes=[0-9]*/#SBATCH --nodes=${new_nodes}/" "$file_path"
    else # Sunnyvale
	sed -i "s/#PBS -l nodes=[0-9]*:ppn=128/#PBS -l nodes=${new_nodes}:ppn=128/" "$file_path"
	change_number_of_processes_starq "$new_nodes"
    fi
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
    echo "$nodes_number" # THIS IS REQUIRED FOR THE CODE TO RUN!

    # Remove the first line from the file
    sed -i '1d' "$file_path"
} #}}}


main() { #{{{
\cp -f nodenumbers.txt.bak nodenumbers.txt
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
	        lines=$((lines-1))
	
	fi
	#echo "Lines are: $lines"

	if [[ $lines -lt 1 ]]; then
	    nodes_number=$(get_nodes)   # Get the number of nodes from the file
	    #echo "Nodes number: $nodes_number"
	    sleep 1
	    if [ ${#nodes_number} -gt 10 ]; then
		exit 0
	    else
		echo "Nodes number: $nodes_number"
	        update_nodes "$nodes_number"  # Update the number of nodes in run.sh
	        ./compile_autosub.sh
	    fi
	fi

        sleep $sleeptime 
done	 
} #}}}

main
