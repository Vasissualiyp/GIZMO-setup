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
    # Ensure archive and last job folders exist
    mkdir -p "$archive_folder" "$last_job_folder"

    # Files to compare
    files_to_compare=("./gizmo/Config.sh" "./template/zel.params")
    no_changes=true

    write_job_id "$job_id" # Assuming job_id is set elsewhere in your script

    for file in "${files_to_compare[@]}"; do
        last_job_file="${last_job_folder}/$(basename $file)"
        changes_detected=false
        
        if [ -f "$last_job_file" ]; then
            # Detect changes and store in a temporary variable
            changes=$(comm -3 <(sort "$file") <(sort "$last_job_file") | awk '
                /^(\t\t)/ { changes_detected=true; print "Added:", $2 }
                /^(\t)/   { changes_detected=true; print "Removed:", $1 }
                !/^(\t)/ && !/^(\t\t)/ { changes_detected=true; print "Edited:", $1, "to", $2 }
            ')

            # If changes were detected, write to the archive file
            if [ "$changes_detected" = true ]; then
                echo "Changes for $file:" >> "$archive_file"
                echo "$changes" >> "$archive_file"
                no_changes=false
            fi
        fi

        # Copy the current file to the last job folder
        cp "$file" "$last_job_file"
    done

    # Add horizontal line if changes detected, or indicate no changes
    if [ "$no_changes" = true ]; then
        echo "No changes detected for this job." >> "$archive_file"
    fi

    echo "====================================" >> "$archive_file" # Horizontal line
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
