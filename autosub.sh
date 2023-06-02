#!/bin/bash

# Ask for the name to be used in the output file
#read -p "Enter the name: " name
name="starqtest"

systemname=$(hostname)

# Get current date and time
current_date=$(date +"%Y.%m.%d")
current_time=$(date +"%H%M")


# Getting the attempt number

# Check if the zel.params file exists
if [ -e zel.params ]; then
    # Read the line from the file
    line=$(grep "OutputDir" zel.params)

    # Extract the date part
    date_part=$(echo "$line" | awk '{print $2}' | cut -d '/' -f 3)
    date_part=$(echo "$date_part" | cut -d ':' -f 1)

    # Check if the date in the OutputDir directory matches today's date
    today=$(date '+%Y.%m.%d')
    echo "${date_part}"
    if [ "$date_part" = "$today" ]; then
        # Extract the number and remove the "/" symbol
        number=$(echo "$line" | awk '{print $2}' | awk -F: '{print $NF}' | tr -d '/')

        # Assign the value to the 'attempt' variable
        attempt=$number

        # Print the value of the 'attempt' variable
        #echo "Attempt: $attempt"
    else
        #echo "The date in the OutputDir directory does not match today's date."
	attempt=0
    fi
else
    attempt=0
fi
attempt=$((attempt+1))
#echo "Attempt: $attempt"

# Copy .params file from template folder
params_file=$(find ./template/ -type f -name "*.params" -print -quit)
if [ -z "$params_file" ]; then
    echo "No .params file found in the template folder."
    exit 1
fi

cp template/zel.params .

# Modify the 'output' line in the .params file
sed -i -e "s|^OutputDir.*|OutputDir\t\t\t\t./output/${current_date}:${attempt}/|" zel.params

echo "The host name is $systemname"

#if [ "$systemname" = "nia-login02.scinet.local" ]; then
if [[ "$systemname" == "nia-login"*".scinet.local" ]]; then


	# Copy run.sh from the template folder
	if [ ! -f ./template/run.sh ]; then
	    echo "run.sh not found in the template folder."
	    exit 1
	fi

	cp ./template/run.sh .

	# Modify the '#SBATCH --output=...' line in the run.sh file and .params file
	sed -i -e "s|^#SBATCH --output=.*|#SBATCH --output=output/${name}_${current_date}:${attempt}|" run.sh
	sed -i -e "s|^#SBATCH --job-name=*|#SBATCH --job-name=${name}_${current_date}:${attempt}|" run.sh
	sed -i -e "s|^MaxMemsize*|MaxMemsize\t\t\t\t3500|" zel.params
	echo "Modifications completed successfully."

	sbatch run.sh
else
	# Copy run.sh from the template folder
	if [ ! -f ./template/run-starq.sh ]; then
	    echo "run-starq.sh not found in the template folder."
	    exit 1
	fi

	cp ./template/run-starq.sh ./run.sh

	# Modify the '#PBS --output=...' line in the run.sh file and .params file
	#sed -i -e "s|^#PBS -o test|#PBS -o output/${name}_${current_date}:${attempt}|" run.sh
	##sed -i -e "s|^#SBATCH --job-name=*|#SBATCH --job-name=${name}_${current_date}:${attempt}|" run.sh
	sed -i -e "s|^MaxMemsize*|MaxMemsize\t\t\t\t7500|" zel.params
	echo "Modifications completed successfully."

#	qsub run.sh
fi
