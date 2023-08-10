# README.md

## GIZMO Setup Scripts

This repository contains scripts for setting up and running GIZMO simulations. The scripts automate the process of configuring GIZMO, submitting jobs to clusters, and generating initial conditions (ICs) for a Zel'dovich pancake simulation.

### Setup Scripts

The `gizmo_setup.sh` script automates the process of cloning the GIZMO repository, configuring the Makefile for different clusters (Niagara or Starq), creating a Config.sh file, and copying the TREECOOL file.

### Submission Scripts

The `autosub.sh` script automates the process of setting up and submitting a job to a cluster. It extracts the job name, creates a unique output directory, modifies necessary parameters based on the host system, and submits the job. Additionally, it tracks changes made to specific parameters in the `./gizmo/Config.sh` and `./template/zel.params` files between job submissions, logging additions, edits, or removals. These changes are archived by date, and the current versions of the files are stored for comparison with the next job submission.

The `compile_and_run.sh` script streamlines the process of compiling and submitting tasks for execution. By incorporating configuration adjustments, it allows the user to automatically clean, compile with desired parameters, and submit tasks to the desired destination without manual intervention. The script offers efficiency and consistency, making it an essential tool for repetitive and complex build and submission procedures.

### Job Management Script
This script allows you to quickly view and cancel running jobs on a cluster using either the `squeue` or `qstat` commands, depending on the host system. It simplifies job management by providing a list of your current jobs with their IDs and runtimes, and lets you easily specify which jobs you want to cancel by their indices.

To run the script, simply execute it in your terminal:

```bash
./job_management.sh
```

### Initial Condition Scripts

The `snapshottimes_generator.py` script generates a geometric sequence of snapshot times between a start time and an end time, and writes these times to a `snapshot_times.txt` file.

The `zeldovich_ics_gen/hdf5zelgenglass.py` script generates 3D initial conditions (ICs) for a Zel'dovich pancake simulation, and writes these ICs to an HDF5 file.

To run these scripts, navigate to the directory containing the scripts and execute them. Note that the scripts may need to be modified to suit your specific simulation setup and computing environment.
