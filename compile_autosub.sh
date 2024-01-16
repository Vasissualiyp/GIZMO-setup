#!/bin/bash

systemname=$(hostname)

# Autosub {{{

# Declare empty arrays to store the configs and parameters
declare -a configs
declare -a parameters

extract_config() { #{{{
  while IFS= read -r line; do
    # Check if the line starts with "Config.sh:"
    if [[ $line == "Config.sh:"* ]]; then
      # Extract the part after "Config.sh:" and add it to the configs array
      configs+=("${line#Config.sh: }") 
    # Check if the line starts with "zel.params:"
    elif [[ $line == "zel.params:"* ]]; then
      # Extract the part after "zel.params:" and add it to the parameters array
      zel_parameters+=("${line#zel.params: }") 
    fi  
  done < "configs.txt"
  # Print the configs and parameters arrays to verify the result
  printf "Extracted configs:\n"
  printf "%s\n" "${configs[@]}"
  printf "\nExtracted parameters:\n"
  #printf "%s\n" "${parameters[@]}"
  printf "%s\n" "${zel_parameters[@]}"
}

#}}}

update_zel_params() { #{{{
  params_file="./template/zel.params"
  param_string="$1"

  # Split the parameter string by spaces
  IFS=' ' read -ra parameters <<< "$param_string"

  # Loop through all the parameters
  for parameter in "${parameters[@]}"; do
    # Check if the parameter starts with a dash, indicating deletion
    if [[ "$parameter" == -* ]]; then
      # Extract the key and delete it from the file (ignoring comments)
      key="${parameter#-}"
      sed -i "/^$key[[:space:]]/d" "$params_file"
      continue
    fi

    # Split the parameter into key and value
    key="${parameter%=*}"
    value="${parameter#*=}"

    # Check if the key already exists in the file (ignoring comments)
    if grep -q "^$key[[:space:]]" "$params_file"; then
      # If the key exists, update the line with the new value
      # Preserve comments at the end of the line
      sed -i "s/^\($key[[:space:]]*\).*\(\s*%.*\)*$/\1$value \2/" "$params_file"
    else
      # If the key does not exist, append the parameter to the file
      echo "$key$value" >> "$params_file"
    fi
  done
}
#}}}

update_softening_zel_params() { #{{{
  params_file="./template/zel.params"
  param_string="$1"

  # Split the parameter string by spaces
  IFS=' ' read -ra parameters <<< "$param_string"

  # Loop through all the parameters
  for parameter in "${parameters[@]}"; do
    # Split the parameter into key and value
    key="${parameter%=*}"
    value="${parameter#*=}"

    if [[ "$key" == "Softening_Type0" ]]; then
      # Change Softening_Type0 and Softening_Type0_MaxPhysLimit to the provided value
      sed -i "s/^\($key\)[[:space:]]\+.*\(\s*%.*\)*$/\1 $value \2/" "$params_file"
      sed -i "s/^\(Softening_Type0_MaxPhysLimit\)[[:space:]]\+.*\(\s*%.*\)*$/\1 $value \2/" "$params_file"
      # Change Softening_Type1 and Softening_Type1_MaxPhysLimit to 10x the value
      #type1_value=$(echo "10 * $value" | bc)
      type1_value=$(awk "BEGIN {print $value * 10}")
      sed -i "s/^\(Softening_Type1\)[[:space:]]\+.*\(\s*%.*\)*$/\1 $type1_value \2/" "$params_file"
      sed -i "s/^\(Softening_Type1_MaxPhysLimit\)[[:space:]]\+.*\(\s*%.*\)*$/\1 $type1_value \2/" "$params_file"
      continue
    fi

    # Check if the parameter starts with a dash, indicating deletion
    if [[ "$parameter" == -* ]]; then
      # Extract the key and delete it from the file (ignoring comments)
      key="${parameter#-}"
      sed -i "/^$key[[:space:]]\+/d" "$params_file"
      continue
    fi

    # Check if the key already exists in the file (ignoring comments)
    if grep -q "^$key[[:space:]]\+" "$params_file"; then
      # If the key exists, update the line with the new value
      # Preserve comments at the end of the line
      #sed -i "s/^\($key\)[[:space:]]\+.*\(\s*%.*\)*$/\1 $value \2/" "$params_file"
      sed -i "s/^\($key\)\([[:space:]]\+\)[0-9]*\(\s*%.*\)*$/\1\2$value\3/" "$params_file"
    else
      # If the key does not exist, append the parameter to the file
      echo -e "$key\t\t\t$value" >> "$params_file"
    fi
  done
}
#}}}

get_name() { #{{{
    first_line=$(head -n 1 ./template/zel.params)
    name="${first_line#*: }"
    #echo "The name of the job is $name"
}
#}}}

get_date_time() { #{{{
    current_date=$(date +"%Y.%m.%d")
    current_time=$(date +"%H%M")
}
#}}}

get_attempt() { #{{{
    if [ -e zel.params ]; then
        line=$(grep "OutputDir" zel.params)
        date_part=$(echo "$line" | awk '{print $2}' | cut -d '/' -f 3)
        date_part=$(echo "$date_part" | cut -d ':' -f 1)
        today=$(date '+%Y.%m.%d')
        if [ "$date_part" = "$today" ]; then
            number=$(echo "$line" | awk '{print $2}' | awk -F: '{print $NF}' | tr -d '/')
            attempt=$number
        else
            attempt=0
        fi
    else
        attempt=0
    fi
    attempt=$((attempt+1))
}
#}}}

copy_and_modify_params() { #{{{
    params_file=$(find ./template/ -type f -name "*.params" -print -quit)
    if [ -z "$params_file" ]; then
        echo "No .params file found in the template folder."
        exit 1
    fi

    cp template/zel.params .

    # Modify the 'output' line in the .params file
    sed -i -e "s|^OutputDir.*|OutputDir\t\t\t\t./output/${current_date}:${attempt}/|" zel.params
}
#}}}

modify_params() { #{{{
    index=$1
    param_string="${zel_parameters[$index]}"
    #echo "param string, index: " "$params_string" "$index"
    update_softening_zel_params "$param_string"
    #update_zel_params "$param_string"
    echo "Modifications of zel.params completed successfully"
}
#}}}

modify_and_submit_job() { #{{{
    systemname=$(hostname)
    current_date=$(date +"%Y-%m-%d")
    bin_dir="./archive/${current_date}/bin/${attempt}"

    # Create the directory if it doesn't exist
    mkdir -p "$bin_dir"

    # Extract the mpirun command from the run.sh script
    #mpirun_command=$(grep -E '^mpirun ' run.sh)
    mpirun_command=$(grep -E '^mpirun ' run.sh)

    # Extract all file paths from the mpirun command
    file_paths=($(echo "$mpirun_command" | awk '{for (i=2; i<=NF; i++) print $i}'))

    # Update the run.sh script with the new mpirun command
    sed -i "s|^mpirun .*|$mpirun_command|" run.sh

    # Submit on Niagara {{{
    if [[ "$systemname" == "nia-login"*".scinet.local" ]]; then 
        cp ./template/run.sh .
        sed -i -e "s|^#SBATCH --output=.*|#SBATCH --output=output/${name}_${current_date}:${attempt}|" run.sh
        sed -i -e "s|^#SBATCH --job-name=*|#SBATCH --job-name=${name}_${current_date}:${attempt}|" run.sh
        sed -i -e "s|^MaxMemSize*|MaxMemSize\t\t\t\t4000|" zel.params
        echo "Modifications of the run.sh file and final modifications of zel.params file completed successfully."

        # Move the files to the archive directory and update the mpirun command
        for file_path in "${file_paths[@]}"; do
            if [ -f "$file_path" ]; then
                cp "$file_path" "$bin_dir"
                mpirun_command=${mpirun_command//$file_path/$bin_dir/$(basename $file_path)}
                cp ./run.sh "$bin_dir"
            fi
        done

        sbatch "$bin_dir"/run.sh
        #echo "Submission complete. Continuing in a second..."
        echo "Submission complete"
        #sleep 1
	  #}}}
    # Submit into starq on Vas-Office-EOS {{{
    elif [[ "$systemname" == "Vas-Office-EOS" ]]; then 
        cp ./template/run-starq.sh ./run.sh
        sed -i -e "s|^MaxMemSize*|MaxMemSize\t\t\t\t4500|" zel.params
        echo "Modifications completed successfully."

        # Move the files to the archive directory and update the mpirun command
        for file_path in "${file_paths[@]}"; do
            if [ -f "$file_path" ]; then
                cp "$file_path" "$bin_dir"
                mpirun_command=${mpirun_command//$file_path/$bin_dir/$(basename $file_path)}
								echo "MPIrun command is:"
								echo "$mpirun_command"
                cp ./run.sh "$bin_dir"
            fi
        done

        qsub run.sh 
	  #}}}
    # Submit into starq on Sunnyvale {{{
    else 
        cp ./template/run-starq.sh ./run.sh
        sed -i -e "s|^MaxMemSize*|MaxMemSize\t\t\t\t7500|" zel.params
        echo "Modifications completed successfully."

        # Move the files to the archive directory and update the mpirun command
        for file_path in "${file_paths[@]}"; do
            if [ -f "$file_path" ]; then
                cp "$file_path" "$bin_dir"
                mpirun_command=${mpirun_command//$file_path/$bin_dir/$(basename $file_path)}
                cp ./run.sh "$bin_dir"
            fi
        done

        if ! command -v qsub &> /dev/null; then
          echo "Error: qsub is not available. Run script from ricky"
          exit 1
        fi

        qsub run.sh 
    fi #}}}

}
#}}}

write_job_id() { #{{{
    archive_folder="./archive"
    last_job_folder="./last_job"
    current_date=$(date +"%Y-%m-%d")
    archive_file="${archive_folder}/${current_date}.txt"
    if [[ "$systemname" == "nia-login"*".scinet.local" ]]; then # Niagara
        job_id=$(squeue -u $USER --format=%i | tail -n +2 | sort -n | tail -n 1)
    else # Sunnyvale
        job_id=$(qstat -u $USER | awk 'NR > 5 && $NF != "--" {split($1, a, "."); print a[1] " " $NF}')
    fi
    echo "Attempt # $attempt" >> "$archive_file"
    echo "Job ID: $job_id" >> "$archive_file"
    echo "------------------------" >> "$archive_file"
}
#}}}

track_changes() { #{{{
    # Files to compare
    # Initialize an empty array
    files_to_compare=()
    
    # Conditionally append files if they exist
    [ -f "./gizmo/Config.sh" ] && files_to_compare+=("./gizmo/Config.sh") || echo "no Config file was found"
    [ -f "./template/zel.params" ] && files_to_compare+=("./template/zel.params") || echo "no parameters file was found"
    [ -f "./music/music_ics.conf" ] && files_to_compare+=("./music/music_ics.conf") || echo "no music file was found"
    
    no_changes=true

    for file in "${files_to_compare[@]}"; do
        last_job_file="${last_job_folder}/$(basename $file)"
        changes_detected=false
        
        if [ -f "$last_job_file" ]; then
            diff_output=$(diff "$last_job_file" "$file")
            changes=$(echo "$diff_output" | awk '/^</ { print "Delete", $2, $3 } /^>/ { print "Add", $2, $3 }')
            echo "$diff_output\n"
            if [ -n "$changes" ]; then
                echo "  " >> "$archive_file"
                echo "Changes for $file:" >> "$archive_file"
                echo "$changes" >> "$archive_file"
                no_changes=false
            fi
        fi

        # Copy the current file to the last job folder
        cp "$file" "$last_job_file"
    done

    if [ "$no_changes" = true ]; then
        echo "No changes detected for this job." >> "$archive_file"
    fi

    echo "  " >> "$archive_file"
    echo "Notes: " >> "$archive_file" # Potential space for notes
    echo "====================================" >> "$archive_file" # Horizontal line

    # For the first attempt of the day, save the parameter files
    params_archive_folder="$archive_folder/$current_date"
    if [ "$attempt" = 1 ]; then
	mkdir "$params_archive_folder"
    fi
    for file in "${files_to_compare[@]}"; do
    	new_filename="$params_archive_folder/$attempt-$(basename $file)"
	#echo "new filename: $new_filename"
    	cp "$file" "$new_filename" 
    done
}
#}}}

autosub() { #{{{
	#echo "Autosubmission..."
	if [ ${#zel_parameters[@]} -eq 0 ]; then
		echo "No parameter changes found. bypassing the change of the parameters file..."
		get_name
		get_date_time
		get_attempt
		copy_and_modify_params
		modify_and_submit_job
		write_job_id
		track_changes
	else
		echo "The full parameters changes:"
		echo "$zel_parameters"
		for ((i = 0; i < ${#zel_parameters[@]}; i++)); do
			get_name
			get_date_time
			get_attempt
			copy_and_modify_params
			modify_params $i
			modify_and_submit_job
			write_job_id
			track_changes
		done
	fi
} #}}}
#}}}

# Compile and submit {{{

update_config() { #{{{
  config_file="./gizmo/Config.sh"

  # Convert all arguments into a single string
  args="$@"

  # Loop through all parameters separated by space
  IFS=' ' read -ra parameters <<< "$args"
  for parameter in "${parameters[@]}"; do
    # Check if the parameter starts with a dash, indicating deletion
    if [[ "$parameter" == -* ]]; then
      # Extract the key and delete it from the file
      key="${parameter#-}"
      sed -i "/^$key/d" "$config_file"
      continue
    fi

    # Check if the parameter contains an '=' sign
    if [[ "$parameter" == *"="* ]]; then
      # Split the parameter into key and value
      key="${parameter%=*}"
      value="${parameter#*=}"

      # Check if the key already exists in the file
      if grep -q "^$key=" "$config_file"; then
        # If the key exists, update the line with the new value
        sed -i "s/^$key=.*/$key=$value/" "$config_file"
      else
        # If the key does not exist, append the parameter to the file
        echo "$key=$value" >> "$config_file"
      fi
    else
      # Handle parameters without an '=' sign
      key="$parameter"

      # Check if the key already exists in the file
      if grep -q "^$key" "$config_file"; then
        # If the key exists, do nothing
        continue
      else
        # If the key does not exist, append the parameter to the file
        echo "$key" >> "$config_file"
      fi
    fi
  done
}
#}}}

compilation() { #{{{
  cd gizmo
  module load intel intelmpi gsl hdf5 fftw
  make clean > /dev/null 
  make -j10 > /dev/null
  cd ..
}
#}}}

# Main run {{{
extract_config
if [ ${#configs[@]} -eq 0 ]; then
  echo "No configurations changes found. Submitting the job, bypassing compilation..."
  autosub
else
  for config in "${configs[@]}"; do
    echo "Compiling..."
    update_config "$config"
    compilation
    echo "Compilation complete! Submitting the job..."
    autosub
    #echo "$config"
  done
fi
#}}}
#}}}
