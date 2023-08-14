#!/bin/bash

# Autosub {{{

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

modify_and_submit_job() { #{{{
    systemname=$(hostname)
    if [[ "$systemname" == "nia-login"*".scinet.local" ]]; then
        cp ./template/run.sh .
        sed -i -e "s|^#SBATCH --output=.*|#SBATCH --output=output/${name}_${current_date}:${attempt}|" run.sh
        sed -i -e "s|^#SBATCH --job-name=*|#SBATCH --job-name=${name}_${current_date}:${attempt}|" run.sh
        sed -i -e "s|^MaxMemsize*|MaxMemsize\t\t\t\t30000|" zel.params
        echo "Modifications completed successfully."
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
	get_name
	get_date_time
	get_attempt
	copy_and_modify_params
	modify_and_submit_job
	write_job_id
	track_changes
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

configs=(
  "PMGRID=32 -MULTIPLEDOMAINS"
  "PMGRID=64"
  "PMGRID=128"
  "PMGRID=256"
  "PMGRID=32 MULTIPLEDOMAINS=16"
  "PMGRID=64"
  "PMGRID=128"
  "PMGRID=256"
  "PMGRID=32 MULTIPLEDOMAINS=32"
  "PMGRID=64"
  "PMGRID=128"
  "PMGRID=256"
  "PMGRID=32 MULTIPLEDOMAINS=64"
  "PMGRID=64"
  "PMGRID=128"
  "PMGRID=256"
) 

# Main run {{{
for config in "${configs[@]}"; do
  update_config $config
  compile_and_submit
  #echo "$config"
done
#}}}
#}}}
