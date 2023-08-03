# DOCUMENTATION.md

## GIZMO Setup Scripts

This repository contains scripts for setting up and running GIZMO simulations. The scripts automate various tasks such as configuring GIZMO, submitting jobs to clusters, and generating initial conditions (ICs) for a Zel'dovich pancake simulation.

### Setup Scripts

#### gizmo_setup.sh

The `gizmo_setup.sh` script automates the process of setting up GIZMO. It performs the following tasks:

1. It first checks the hostname of the current system to determine whether it is running on the Niagara or Starq cluster.
2. The script then clones the GIZMO repository from Bitbucket into the current directory.
3. Depending on the system name determined earlier, it modifies the `Makefile.systype` file in the GIZMO directory to set the appropriate `SYSTYPE` variable.
4. It copies the `TREECOOL` file from the `cooling` directory in the GIZMO repository to the current directory.
5. The script creates a `Config.sh` file with some predefined configuration flags.
6. Finally, it opens the newly created `Config.sh` file in vim for further editing.

The script can be customized by modifying the predefined configuration flags in the `Config.sh` file or by adding additional steps to the setup process.

### Submission Scripts

#### autosub.sh

The `autosub.sh` script automates the process of setting up and submitting a job to a cluster. It performs the following tasks:

1. Extracts the name of the job from the `zel.params` file in the `template` directory.
2. Determines the host system (Niagara or Starq) based on the system's hostname.
3. Retrieves the current date and time.
4. Checks if an existing simulation job has been executed on the same day. If so, it increments an `attempt` counter.
5. Copies the `zel.params` file from the `template` directory to the current directory, and updates the `OutputDir` in the copied `zel.params` file to reflect the current date and attempt number.
6. Depending on the host system (Niagara or Starq), it copies the corresponding run script (`run.sh` for Niagara or `run-starq.sh` for Starq) from the `template` directory to the current directory. It then modifies the output directory and job name in the run script to reflect the current date, attempt number, and job name.
7. Finally, it submits the job to the host system's job scheduler.

### Job Management Script

This script is designed to streamline job management on clusters that use either the Slurm or Torque/PBS job schedulers. The script determines the appropriate command to use (`squeue` for Slurm or `qstat` for Torque/PBS) based on the hostname of the system. 

#### Usage

To run the script, simply execute it in your terminal:

```bash
./job_management.sh
```

The script will display a list of your current jobs, including their job IDs and runtimes. Each job will be numbered with an index. 

```
Here are your currently running jobs:
1: 12345 0:10:00
2: 12346 0:20:00
3: 12347 0:30:00
...
```

You will then be prompted to enter the indices of the jobs you wish to cancel:

```
Enter the indices of jobs you want to cancel (e.g. 1,3-5):
```

Enter the indices of the jobs you want to cancel, separating individual indices with commas and specifying ranges with a dash. For example:

* To cancel the first job, enter: `1`
* To cancel the first and third jobs, enter: `1,3`
* To cancel the first through fourth jobs, enter: `1-4`
* To cancel the first job and third through fifth jobs, enter: `1,3-5`

#### Notes

* The indices are 1-based (the first job is 1). 
* Please be careful when using this script and double-check the jobs you're about to cancel before confirming. 
* This script should be tested in a safe environment before being used in a production environment. 
* Make sure the path to `bash` in the shebang (`#!/bin/bash`) at the top of the script matches the path on your systems.

### Initial Condition Scripts

#### snapshottimes_generator.py

The `snapshottimes_generator.py` script generates a geometric sequence of snapshot times between a start time and an end time. Here is a detailed breakdown:

1. It sets the start time (`t1`), end time (`t2`), and the number of snapshots (`n`).
2. The script then generates a geometric sequence of snapshot times between `t1` and `t2` using the numpy `logspace` function.
3. These snapshot times are printed to the console.
4. Finally, the script writes the generated snapshot times to a file named `snapshot_times.txt` in the parent directory.

The start time, end time, and number of snapshots can be adjusted according to the specific requirements of the simulation. The output file can also be changed to match the desired file structure.

#### hdf5zelgenglass.py

The `hdf5zelgenglass.py` script in the `zeldovich_ics_gen` directory generates the initial conditions (ICs) for a Zel'dovich pancake simulation in a format that the Arepo code can read. Here is a breakdown of its functions:

1. It first defines some constants and parameters for the simulation, such as the box size, the number of cells, and the initial temperature.
2. The script then sets up a 3D Cartesian grid of cells and calculates the mass, velocity, and specific internal energy for each cell based on the Zel'dovich pancake solution.
3. It also calculates the peculiar and comoving velocities of the cells.
4. Finally, it writes all this data, along with some header attributes that the Arepo code uses to set up the simulation, to an HDF5 file named `IC.hdf5`.

This script can be modified to create ICs for different types of cosmological simulations, by changing the functions used to calculate the initial conditions.
