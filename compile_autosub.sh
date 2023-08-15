#!/bin/bash

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

# Print the configs and parameters arrays to verify the result
#printf "Extracted configs:\n"
#printf "%s\n" "${configs[@]}"
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
      sed -i "s/^\($key\)[[:space:]]\+.*\(\s*%.*\)*$/\1 $value \2/" "$params_file"
    else
      # If the key does not exist, append the parameter to the file
      echo "$key$value" >> "$params_file"
    fi
  done
}
#}}}

get_name() { #{{{
    first_line=$(head -n 1 ./template/zel.params)
    name="${first_line#*: }"
    echo "The name of the job is $name"
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
    echo "param string, index: " "$params_string" "$index"
    update_softening_zel_params "$param_string"
    #update_zel_params "$param_string"
    echo "Modifications of zel.params completed successfully"
}
#}}}

modify_and_submit_job() { #{{{
    systemname=$(hostname)
    if [[ "$systemname" == "nia-login"*".scinet.local" ]]; then
        cp ./template/run.sh .
        sed -i -e "s|^#SBATCH --output=.*|#SBATCH --output=output/${name}_${current_date}:${attempt}|" run.sh
        sed -i -e "s|^#SBATCH --job-name=*|#SBATCH --job-name=${name}_${current_date}:${attempt}|" run.sh
        sed -i -e "s|^MaxMemsize*|MaxMemsize\t\t\t\t30000|" zel.params
        echo "Modifications of the run.sh file and final modifications of zel.params file completed successfully."
        sbatch run.sh
    else
        cp ./template/run-starq.sh ./run.sh
        sed -i -e "s|^MaxMemsize*|MaxMemsize\t\t\t\t7500|" zel.params
        echo "Modifications completed successfully."
        qsub run.sh
    fi
}
#}}}

write_job_id() { #{{{
    archive_folder="./archive"
    last_job_folder="./last_job"
    current_date=$(date +"%Y-%m-%d")
    archive_file="${archive_folder}/${current_date}.txt"
    job_id=$(squeue -u $USER --format=%i | tail -n +2 | sort -n | tail -n 1)
    echo "Attempt # $attempt" >> "$archive_file"
    echo "Job ID: $job_id" >> "$archive_file"
    echo "------------------------" >> "$archive_file"
}
#}}}

track_changes() { #{{{
    # Files to compare
    files_to_compare=("./gizmo/Config.sh" "./template/zel.params")
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
	echo "Autosubmission..."
	if [ ${#zel_parameters[@]} -eq 0 ]; then
		echo "No parameter changes found. bypassing the change of the parameters file..."
	else
		echo "The full parameters changes:"
		echo "$zel_parameters"
		for ((i = 0; i < ${#zel_parameters[@]}; i++)); do
			echo "Step " "$i"
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

  # Loop through all arguments given to the function
  for parameter in "$@"; do
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

compile_and_submit() { #{{{
  cd gizmo
  module load intel intelmpi gsl hdf5 fftw
  make clean
  make -j10
  cd ..
  autosub
}
#}}}

# Main run {{{
extract_config
if [ ${#configs[@]} -eq 0 ]; then
  echo "No configurations changes found. Bypassing compilation..."
  autosub
else
  for config in "${configs[@]}"; do
    echo "Compiling..."
    update_config "$config"
    compile_and_submit
    #echo "$config"
  done
fi
#}}}
#}}}
