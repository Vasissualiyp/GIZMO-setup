# README.md

## GIZMO Setup Scripts

This repository contains scripts for setting up and running GIZMO simulations. The scripts automate the process of configuring GIZMO, submitting jobs to clusters, and generating initial conditions (ICs) for a Zel'dovich pancake simulation.

### Setup Scripts

The `gizmo_setup.sh` script automates the process of cloning the GIZMO repository, configuring the Makefile for different clusters (Niagara or Starq), creating a Config.sh file, and copying the TREECOOL file.

### Submission Scripts

The `autosub.sh` script automates the process of setting up and submitting a job to a cluster. It extracts the job name from the `zel.params` file, determines the host system, creates a unique output directory based on the current date and an attempt number, and modifies the run script to reflect these changes. Finally, it submits the job to the host system's job scheduler.

### Initial Condition Scripts

The `snapshottimes_generator.py` script generates a geometric sequence of snapshot times between a start time and an end time, and writes these times to a `snapshot_times.txt` file.

The `zeldovich_ics_gen/hdf5zelgenglass.py` script generates 3D initial conditions (ICs) for a Zel'dovich pancake simulation, and writes these ICs to an HDF5 file.

To run these scripts, navigate to the directory containing the scripts and execute them. Note that the scripts may need to be modified to suit your specific simulation setup and computing environment.
