**This documentation was last updated on 2023.10.17**

## GIZMO Setup Scripts

This repository contains scripts for setting up and running GIZMO simulations. The scripts automate the process of configuring GIZMO, submitting jobs to clusters, and generating initial conditions (ICs) for a Zel'dovich pancake simulation.

## Structure of scripts

All but one scripts are located in the `scripts` folder. It is recommended that you run all scripts from current directory, i.e. `./scripts/gizmo_setup.sh`. 

Most of the scripts automatically detect your system (currently supported: ScieNet Niagara and CITA Sunnyvale), and execute appropriate commands. 

For more information about the structure of the folders, and information about the code, check `DOCUMENTATION.md`.

### Setup Scripts

The `gizmo_setup.sh` script automates the process of cloning the GIZMO repository, configuring the Makefile for different clusters (Niagara or Starq), creating a Config.sh file, and copying the TREECOOL file. Currently it also includes downloading spcool tables for GIZMO native cooling library.

The `music_setup.sh` script automatically clones the MUSIC suite for cosmological ICs generation into the `./music` folder.

### Submission Scripts

The `compile_autosub.sh` script (the only script not in the `scripts` folder) automates the process of setting up and submitting a job to a cluster. It extracts the job name, creates a unique output directory, modifies necessary parameters based on the host system, and submits the job. Additionally, it tracks changes made to specific parameters in the `./gizmo/Config.sh` and `./template/zel.params` files between job submissions, logging additions, edits, or removals. These changes are archived by date, and the current versions of the files are stored for comparison with the next job submission. 

### Job Management Script

The script `sqc.sh` allows you to quickly view and cancel running jobs on a cluster using either the `squeue` or `qstat` commands, depending on the host system. It simplifies job management by providing a list of your current jobs with their IDs and runtimes, and lets you easily specify which jobs you want to cancel by their indices. The script updates the job progress in real time.

The script `job_tracker.sh` works like sqc.sh, except it tracks the current timestep of the latest simulation.

The script `day_clear.sh` clears all jobs from today and resets the directory as if no jobs were ran today.

### Job Performance Mangement

The script `performance_report.sh` writes current timestep of the simulation and real time since the script was started into a csv file in the directory where the simulation is running. This script is useful if you want to track how fast does the simulation progress with time. You should run this script at the same time as the job is running. What I would suggest is running this script at the same time with `sqc.sh` to make sure that you are not tracking inactive jobs. For this script, it is also very important to set its maximum time of running if you are going to make it run automatically with `nohup` (in the background, with possibility of logging out)

`heatmap_generator.py` and `runtime_check.ccp` are legacy scripts that were used to check the dependence of short run speed (max timestep) on a pair of parameters. They create a heatmap that should in theory show which jobs perform the best. Should be used in combination with `generate_configs.py` script for generation of 'grid' of parameters for the heatmap and with `compile_autosub.sh` script for batch job submission. Currently the axes for heatmap have to be set manually in the script.

### Initial Condition Scripts

The `snapshottimes_generator.py` script generates a geometric sequence of snapshot times between a start time and an end time, and writes these times to a `snapshot_times.txt` file.

The `zeldovich_ics_gen/hdf5zelgenglass.py` script generates 3D initial conditions (ICs) for a Zel'dovich pancake simulation, and writes these ICs to an HDF5 file.

To run these scripts, navigate to the directory containing the scripts and execute them. Note that the scripts may need to be modified to suit your specific simulation setup and computing environment.
