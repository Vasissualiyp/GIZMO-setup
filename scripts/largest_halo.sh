#!/bin/bash

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

  ics_filename="ICs_${seed_lvl}_$seed.dat"

  echo "Generating ICs for seed ${seed} at the level ${seed_lvl} using template ${template_config}..."

  cd "$MAIN_DIR" 

  rm "./music/$music_conf"
  cp "$template_config" "./music/$music_conf"

  cd ./music || { echo "No MUSIC directory. Make sure to set it up"; exit 1; }

  #sed -i "s/seed\[$seed_lvl\] = .*/seed[$seed_lvl] = $seed/" "$music_conf" # would replace any seed lvl
  sed -i "s/seed\[\$seed_lvl\] = .*/seed[$seed_lvl] = $seed/" "$music_conf" # would only replace a certain seed lvl
  sed -i "/.*IC.*/c\filename = ../$ics_filename" "./$music_conf" # sets appropriate output filename

  ./MUSIC "./$music_conf" && echo "ICs have been created!"
  cd ..
  # Insert command to modify template configuration and generate ICs here.
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
  echo "Running GIZMO with ${ics_path} and parameters from ${template_params}..."

  # Insert command to run GIZMO with the specified ICs and parameter file here.
}

# Monitors the GIZMO simulation process, checking periodically to see if it is still active.
# This function is crucial for determining when a simulation has completed, allowing the
# script to proceed with post-processing steps. The method of monitoring (e.g., checking process
# existence or file output) should be chosen based on the specifics of the GIZMO execution environment.
monitor_gizmo() {
  echo "Monitoring GIZMO process..."
  # Insert process monitoring commands here, adjusting as necessary for your environment.
}

# Processes the output of a completed GIZMO simulation, typically by moving or organizing
# simulation snapshot files into a designated directory. This organization facilitates easier
# access to simulation results for analysis or further processing.
# Arguments:
#   1. Output directory - The directory where processed output should be stored.
process_output() {
  local output_dir="$1"
  echo "Processing output to ${output_dir}..."
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
  for seed in "${seeds[@]}"; do
    generate_ics "$seed" "$seed_lvl" "$template_config" "$music_conf"
    run_gizmo "ics_path" "template_params.conf"
    monitor_gizmo
    process_output "output_dir"
    run_rockstar "snapshots_dir" 30 15 4
    log_info "$seed" "snapshots_path" "ics_path" "30 15 4" "halo_size"
    # Implement logic for running tasks of the previous seed while GIZMO runs the next seed.
  done
}

# Execute the main function with all passed arguments.
main "$@"

