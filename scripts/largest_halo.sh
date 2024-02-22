#!/bin/bash


systemname=$(hostname)

# function to process squeue for Niagara 
function run_squeue {
  echo "Here are your currently running jobs:"
  data=$(squeue -u $USER -o "%.18i %.10M" --noheader)
  readarray -t lines <<<"$data"

  for i in "${!lines[@]}"; do
    echo "$((i+1)): ${lines[i]}"
  done
}


# Helper function to check if there are jobs running 
function are_jobs_running {
  # Depending on the system, set the appropriate command to check jobs
  if [[ "$systemname" == "nia-login"*".scinet.local" ]]; then
    data=$(squeue -u $USER --noheader)
  else
    data=$(qstat -u $USER | awk 'NR > 5')
  fi

  # If data is not empty, jobs are running
  [[ -n "$data" ]]
}


# function to process qstat for Sunnyvale 
function run_qstat {
  if ! command -v qstat &> /dev/null; then
    echo "Please ssh to ricky to run this script"
    exit 1
  fi
  echo "Here are your currently running jobs:"

  data=$(qstat -u $USER | awk 'NR > 5 {split($1, a, "."); print a[1] " " $NF}')
  readarray -t lines <<<"$data"

  for i in "${!lines[@]}"; do
    echo "$((i+1)): ${lines[i]}"
  done
}


# Initializes the script environment, setting up necessary variables, directories, and templates.
# It also prepares the environment by loading required modules or setting software paths,
# ensuring that all subsequent operations can be executed smoothly.
initialize_environment() {
  echo "Initializing environment..."
  # Add environment setup commands here, like module loads or directory creation.
  # This works for Sunnyvale:
  #module purge; module load gcc openmpi/4.1.6-intel-ucx gsl hdf5 fftw/3.3.10

  # Get the directory where the script is located
  SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
  MAIN_DIR="$( cd "$SCRIPT_DIR/.." && pwd )" # Get into the folder with music, rockstar, etc.
}

# Generates initial conditions (ICs) for a GIZMO simulation using a specified seed and a template
# configuration file. This function is responsible for modifying the template configuration
# with the given seed, then invoking the IC generation tool or script.
# Arguments:
#   1. Seed - The seed number for the random number generator, ensuring reproducibility.
#   2. Template configuration file path - The path to the template configuration file.
generate_ics() {
  local seed="$1"
  local seed_lvl="$2"
  local template_config="$3"
  local music_conf="$4"
  echo "Generating ICs for seed ${seed} at the level ${seed_lvl} using template ${template_config}..."
  cd "$MAIN_DIR" 

  ics_filename="ICs_${seed_lvl}_$seed"

  cp "$template_config" "./music/$music_conf"

  cd ./music || { echo "No MUSIC directory. Make sure to set it up"; exit 1; }

  #sed -i "s/seed\[$seed_lvl\] = .*/seed[$seed_lvl] = $seed/" "$music_conf" # would replace any seed lvl
  sed -i "s/seed\[\$seed_lvl\] = .*/seed[$seed_lvl] = $seed/" "$music_conf" # would only replace a certain seed lvl
  sed -i "/.*IC.*/c\filename = ../$ics_filename.dat" "./$music_conf" # sets appropriate ICs filename

  ./MUSIC "./$music_conf" && echo "ICs have been created!"
}

# Runs the GIZMO simulation with the generated initial conditions and a set of parameters.
# This involves invoking GIZMO with the correct command-line arguments, including paths
# to the ICs and the parameter file. Monitoring of the GIZMO process to ensure it is running
# correctly is also initiated here.
# Arguments:
#   1. ICs path - Path to the initial conditions file.
#   2. Template parameters file path - Path to the simulation parameter template file.
run_gizmo() {
  local ics_path="$1"
  local template_params="$2"
  local params_file="$3"
  echo "Running GIZMO with ${ics_path} and parameters from ${template_params}..."
  cd "$MAIN_DIR" 

  #rm "$params_file"
  cp "$template_params" "$params_file"
  sed -i "1s/.*/% Name of the file: $ics_filename/" "$params_file" # Changes the name of the job
  escaped_ics_path=$(printf '%s\n' "$ics_path" | sed 's:/:\\/:g')
  echo "$escaped_ics_path"
  sed -i "/^InitCondFile/c\InitCondFile\t\t\t\t$escaped_ics_path" "$params_file"

  ./compile_autosub.sh

  snapshots_dir=$(grep 'OutputDir' ./zel.params | awk '{print }') # get the directory for the snapshots
}

# Monitors the GIZMO simulation process, checking periodically to see if it is still active.
# This function is crucial for determining when a simulation has completed, allowing the
# script to proceed with post-processing steps. The method of monitoring (e.g., checking process
# existence or file output) should be chosen based on the specifics of the GIZMO execution environment.
function monitor_gizmo {
  echo "Monitoring running jobs..."
  cd "$MAIN_DIR" 
  while are_jobs_running; do
    echo "Jobs are still running. Waiting..."
    sleep 60  # Wait for 60 seconds before checking again
  done
  echo "No more running jobs. Proceeding..."
}

# Processes the output of a completed GIZMO simulation, typically by moving or organizing
# simulation snapshot files into a designated directory. This organization facilitates easier
# access to simulation results for analysis or further processing.
# Arguments:
#   1. Output directory - The directory where processed output should be stored.
process_output() {
  local output_dir="$1"
  local snapshots_dir="$2"
  echo "Processing output from ${snapshots_dir} to ${output_dir}..."
  cd "$MAIN_DIR" 
  # Insert commands to move or organize GIZMO output here.
}

# Runs the Rockstar halo finder on the simulation snapshots to identify the largest haloes
# at specified redshifts. This function should invoke Rockstar with appropriate parameters
# and handle the output to extract information about the largest haloes.
# Arguments:
#   1. Snapshots directory - Directory containing the simulation snapshots.
#   2. Redshifts - A list of redshifts at which to find the largest haloes.
run_rockstar() {
  local snapshots_dir="$1"
  shift # Remove the first argument, leaving only redshifts.
  local redshifts=("$@") # Remaining arguments are redshifts.
  echo "Running Rockstar on snapshots in ${snapshots_dir} for redshifts: ${redshifts[*]}..."
  cd "$MAIN_DIR" 
  # Insert command to run Rockstar and extract halo information here.
}

# Logs key information about the simulation run to a CSV file for easy reference and analysis.
# This includes the seed used for initial conditions, paths to the snapshots and ICs,
# the redshifts analyzed, and the size of the largest halo found.
# Arguments:
#   1. Seed - The seed number used for the simulation's initial conditions.
#   2. Snapshots path - Path to the directory containing the simulation snapshots.
#   3. ICs path - Path to the initial conditions file.
#   4. Redshift - Redshifts at which the largest haloes were analyzed.
#   5. Largest halo size - The size of the largest halo found at each redshift.
log_info() {
  local seed="$1"
  local snapshots_path="$2"
  local ics_path="$3"
  local redshift="$4"
  local halo_size="$5"
  echo "Logging information for seed ${seed}..."
  cd "$MAIN_DIR" 
  # Insert command to log information to a CSV file here.
}

# The main loop of the script, executing the workflow for each seed specified by the user.
# This involves generating ICs, running the GIZMO simulation, monitoring its progress,
# processing the output, running Rockstar to find the largest haloes, and logging all relevant information.
main() {
  initialize_environment
  local seeds=(11235 24654 33212) # Example seed array. Replace or extend as required.
  local seed_lvl=7 
  local music_conf="largest_halo.conf"
  local template_config="./template/largest_halo/dm_only_ics.conf"
  local template_gizmo_params="./template/largest_halo/gizmo.params"
  local params_file="./template/zel.params"
  local output_dir="./"
  for seed in "${seeds[@]}"; do
    generate_ics "$seed" "$seed_lvl" "$template_config" "$music_conf" # ics_filename is defined in generate_ics()
    run_gizmo "$MAIN_DIR/$ics_filename.dat" "$template_gizmo_params" "$params_file"
    monitor_gizmo
	process_output "$output_dir" "${snapshots_dir}" # snapshots_dir is defined in run_gizmo()
    run_rockstar "snapshots_dir" 30 15 4
    log_info "$seed" "snapshots_path" "ics_path" "30 15 4" "halo_size"
    # Implement logic for running tasks of the previous seed while GIZMO runs the next seed.
  done
}

# Execute the main function with all passed arguments.
main "$@"
                                                                                                                   
