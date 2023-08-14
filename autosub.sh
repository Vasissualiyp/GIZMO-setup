#!/bin/bash

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

    echo "====================================" >> "$archive_file" # Horizontal line

    # For the first attempt of the day, save the parameter files
    if [ "$attempt" = 1 ]; then
	params_archive_folder="$archive_folder/$current_date"
	mkdir "$params_archive_folder"
    fi
    for file in "${files_to_compare[@]}"; do
    	new_filename="$params_archive_folder/$attempt-$(basename $file)"
    	cp "$file" "$new_filename" 
    done
}
#}}}

# Main part of the script
get_name
get_date_time
get_attempt
copy_and_modify_params
modify_and_submit_job
write_job_id
track_changes
