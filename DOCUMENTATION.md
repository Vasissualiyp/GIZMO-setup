# DOCUMENTATION.md
**This Documentation was last updated on 2023.10.25**

## GIZMO Setup Scripts

This repository contains scripts for setting up and running GIZMO simulations. The scripts automate various tasks such as configuring GIZMO, submitting jobs to clusters, and generating initial conditions (ICs) for a Zel'dovich pancake simulation.

## Setup Scripts

### `gizmo_setup.sh`

#### Description

The `gizmo_setup.sh` script is designed to automate the setup of the GIZMO codebase. It performs system-specific configurations and clones the GIZMO repository, preparing it for subsequent simulation runs.

#### Usage

To run the script, execute:

```bash
./scripts/gizmo_setup.sh
```

#### Key Functionalities

1. **System Identification**: The script checks the hostname to identify the current system (Niagara or Starq), setting configurations accordingly.

2. **Directory Preparation**: Creates the `archive`, `output`, and `last_job` directories if they don't already exist.

3. **Repository Cloning**: Clones the GIZMO repository from Bitbucket into the current directory. It has provisions for cloning either a public, private or starforge repository. It inquires which repository the user is interested in before cloning.

4. **Makefile Configuration**: Modifies the `Makefile.systype` file in the newly cloned GIZMO directory. It sets the `SYSTYPE` variable based on the identified system (Niagara or Starq).

#### Additional Notes

- The script allows for flexibility in choosing which GIZMO repository to clone (public, private, or starforge).
- It prepares the environment by creating necessary directories (`archive`, `output`, `last_job`, etc.) for storing simulation data and outputs.

### `music_setup.sh`

#### Description

The `music_setup.sh` script is a Bash utility that automates the cloning and setup of the MUSIC Initial Condition Generator from its Bitbucket repository.

#### Usage

To run the script, navigate to the root directory and execute:

```bash
./scripts/music_setup.sh
```

#### Key Functionalities

1. **Git Cloning**: The script clones the MUSIC repository from Bitbucket using the `git clone` command.

2. **Directory Navigation**: After cloning, the script changes the working directory to the newly created `music` folder.

#### Additional Notes

- The script is straightforward and serves the purpose of simplifying the initial setup of the MUSIC software.
- No error handling or additional functionalities are currently implemented.

## Submission Scripts

### `compile_autosub.sh`

#### Description

`compile_autosub.sh` is a Bash script designed to automate the submission and management of GIZMO simulation jobs on a cluster. It supports various configuration files including `Config.sh`, `zel.params`, and `dm+b_ics.conf` for MUSIC initial conditions.

#### Usage

To execute the script, run:

```bash
./compile_autosub.sh
```

#### Key Functionalities

1. **System Identification**: The script identifies the host system (Niagara or Starq) based on the hostname for cluster-specific configurations.

2. **Configuration Extraction**: It reads a `configs.txt` file to parse configurations for `Config.sh`, `zel.params`, and `dm+b_ics.conf`.

3. **Parameter File Management**: Updates and customizes parameter files like `zel.params` and `dm+b_ics.conf` based on the extracted configurations. These files are copied from a `template` directory to a newly created directory.

4. **Dynamic Directory Creation**: A new directory is created based on the current date and an "attempt" counter, which increments for multiple job submissions on the same day.

5. **Run Script Handling**: The script fetches and customizes the appropriate run script (`run.sh` or `run-starq.sh`) from the `template` directory based on the host system.

6. **Job Submission**: Submits the job to the cluster after preparing all necessary files.

7. **Archiving**: An archiving mechanism is included to move old simulation files to an archive directory, maintaining an organized workspace.

8. **Logging**: Various details like attempt number, job ID, and changes are logged into a text file within the archive directory.

#### Additional Notes

- The script uses associative arrays to store configurations and parameters, allowing for easy management and updates.
- Error checks and validations are included at different stages to ensure robust functioning.

## Job Management Scripts

### `sqc.sh`

#### Description

The `sqc.sh` script is a Bash utility designed to continually update the queue status for the user's jobs on the Niagara supercomputer. It fetches the job information using the `sqc -u $USER` command and displays it on the terminal.

#### Usage

To run the script, navigate to the root directory and execute:

```bash
./scripts/sqc.sh
```

#### Key Functionalities

1. **System Identification**: Checks the system hostname to determine if it is running on Niagara.
  
2. **Queue Status**: Fetches the current job queue status using the `sqc -u $USER` command.

3. **Continuous Update**: The script runs in an infinite loop, updating the queue status every second (configurable via the `sleeptime` variable).

4. **Display Formatting**: Manages terminal display to ensure that the queue information is presented neatly.

#### Additional Notes

- The script is specifically designed for use on the Niagara supercomputer.
- It employs basic terminal commands for cursor manipulation and display formatting.
- There is no error-handling mechanism in place, so the user should ensure correct configurations.
- The script is intended for use within this specific project's ecosystem and may require modifications for broader applications.

### `job_tracker.py`

#### Description

The `job_tracker.py` script is a Python utility designed to monitor and log CPU usage on the cluster. The script uses the Watchdog library to track changes in a `cpu.txt` file and writes the CPU usage to a CSV file.

#### Usage

To run the script, navigate to the root directory and execute:

```bash
./scripts/job_tracker.py
```

#### Key Functionalities

1. **Watchdog Observer**: Utilizes the Watchdog library's Observer class to monitor changes to the file system.

2. **Event Handling**: Defines a custom event handler (`CPUHandler`) that triggers when `cpu.txt` is modified. It reads the last 35 lines of the file to gather CPU usage data.

3. **CSV Logging**: Writes the monitored CPU usage to a specified CSV file. The CSV contains fields like 'user', 'system', 'idle', etc., which are populated based on the parsed `cpu.txt`.

4. **Time-stamping**: Each entry in the CSV file is time-stamped using Python's datetime library.

#### Additional Notes

- The script is specifically tailored to monitor CPU usage, and the format of the logged data is influenced by the structure of `cpu.txt`.
- It operates in real-time, constantly monitoring for changes and updating the CSV log accordingly.

### `job_cancel.sh`

#### Description

The `job_cancel.sh` script is a Bash utility designed to manage and cancel running jobs on different clusters, specifically Niagara and Sunnyvale. It uses the `squeue` and `qstat` commands to display and process job queues.

#### Usage

To run the script, execute:

```bash
./scripts/job_cancel.sh
```

You will then be prompted to enter the indices of the jobs you wish to cancel:

Enter the indices of the jobs you want to cancel, separating individual indices with commas and specifying ranges with a dash. For example:

* To cancel the first job, enter: `1`
* To cancel the first and third jobs, enter: `1,3`
* To cancel the first through fourth jobs, enter: `1-4`
* To cancel the first job and third through fifth jobs, enter: `1,3-5`

#### Key Functionalities

1. **System Identification**: The script identifies the current system based on the hostname and uses either `squeue` for Niagara or `qstat` for Sunnyvale to manage jobs.

2. **Job Listing**: It lists all currently running jobs belonging to the user, displaying the job ID and time.

3. **Job Cancellation**: The script prompts the user to specify which job(s) to cancel. It then cancels the selected job(s) using `scancel` for Niagara or `qdel` for Sunnyvale.

4. **Error Handling**: Includes checks to validate the presence of `qstat` command when on Sunnyvale and exits if the command is not available.

#### Additional Notes

- The script makes use of read arrays to store the output of `squeue` and `qstat`, making it easier to process and display job data.
- The script is interactive, prompting the user for inputs to select which jobs to cancel.

### `job_scheduler.sh`

#### Description

**This script might be malfunctioning, use at your own risk!**

The `job_scheduler.sh` script is a Bash utility intended for automatically scheduling jobs on the cluster. When run, it enters a loop that checks the job queue and triggers the `compile_autosub.sh` script when no jobs are found for the user. 

Main difference between this utility and using several config files for `compile_autosub.sh` is that this script submits one job to run after another, while `compile_autosub.sh` submits all jobs at once.

Another thing is that this script runs in the background with `nohup`, so you can log out and the jobs will be submitted automatically

#### Usage

To execute the script, excute:

```bash
./scripts/job_scheduler.sh
```

#### Key Functionalities

1. **Dependency Check**: The script checks for the presence of the `qstat` command and exits if not found, suggesting that the user ssh into Ricky.

2. **Job Queue Monitoring**: Uses `qstat` to monitor the job queue for the current user. Specifically, it looks for jobs that are still in the queue and belong to the user.

3. **Auto Scheduling**: If no jobs are found for the current user, the script triggers the `compile_autosub.sh` script to schedule a new job.

4. **Loop and Sleep**: The script runs in a loop and sleeps for 60 seconds between each check of the job queue.

#### Additional Notes

- The script employs `readarray` to read the job queue details into an array, which is then processed to determine whether any jobs are still active for the user.
- It uses `nohup` and `bash -c` to run the script in the background, logging its output to `nohup_job_scheduler.out`.

### `day_clear.sh`

#### Description

`day_clear.sh` is a Bash script that automates the process of cleaning up directories that contain older simulation data. It deletes specific folders and files from the `archive` and `output` directories based on the current date.

#### Usage

To execute the script, run:

```bash
./day_clear.sh
```

#### Key Functionalities

1. **Date Fetching**: The script fetches the current date in both `YYYY-MM-DD` and `YYYY.MM.DD` formats.

2. **Directory and File Removal**: It removes directories in the `./archive/` and `./output/` folders that match the current date.

3. **Parameter Update**: The script updates the `zel.params` file to reflect a new output directory based on the date. It uses Vim's search-and-replace functionality for this update.

#### Additional Notes

- The script calculates the "yesterday" date and uses it for Vim's find-and-replace operation in `zel.params`.

## Job Performance Management

### `performance_report.sh`

#### Description

The `performance_report.sh` script is a Bash utility designed to generate performance reports for simulation runs. It identifies the latest attempt and outputs key performance metrics based on cpu.txt file. It saves the output into the csv file in the directory of the cpu.txt.

#### Usage

To run the script, navigate to the root directory and execute:

```bash
./scripts/performance_report.sh
```

#### Key Functionalities

1. **Latest Attempt Identification**: Utilizes a function to find the latest attempt number if not provided by the user.

2. **Time Limit**: Sets a maximum runtime for the script, defaulting to 12 hours.

3. **Log File Parsing**: Parses through log files to gather information on various parameters like CPU usage and memory consumption.

4. **Report Generation**: Outputs a performance report detailing the key metrics gathered from the log files.

#### Additional Notes

- The script assumes specific directory structures and file naming conventions.
- No error-handling mechanisms are in place, so the user should be cautious while using the script.
- The script is intended for use within this specific project's ecosystem and may require modifications for broader applications.

### `generate_configs.py`

#### Description

The `generate_configs.py` script is a Python utility designed to automate the generation of configuration files (`Config.sh` and `zel.params`) for GIZMO simulations. It dynamically generates various configurations based on specified parameter ranges and saves them for future use.

#### Usage

To execute the script, run:

```bash
python ./scripts/generate_configs.py
```

#### Key Functionalities

1. **Softening Calculations**: The script calculates a range of softening values using a logarithmic scale. These values are later used for generating variations in the `zel.params` file.

2. **Power of 2 Calculations**: It computes powers of 2 for certain parameters, which are then used in the configuration files.

3. **Parameter Definitions**: Parameters and their potential values are defined in a dictionary. For `Config.sh`, it considers variations in the `MULTIPLEDOMAINS` parameter. For `zel.params`, it considers variations in the `Softening_Type0` parameter.

4. **Parameter Removal**: The script has a provision for defining parameters that should be removed only for the first run. This is currently set as an empty list for `Config.sh`.

5. **File Generation**: Iterates through the defined parameters and their possible values, and generates variations of `Config.sh` and `zel.params` files with these parameters.

#### Additional Notes

- The script utilizes NumPy for numerical calculations, making it efficient for generating a large set of configurations.
- It employs Python's itertools for generating combinations of parameters, making it highly customizable and extensible.

### `heatmap_generator.py`

#### Description

The `heatmap_generator.py` script is a Python script for generating heatmaps based on GIZMO simulation data. It uses matplotlib for plotting and numpy for numerical operations.

#### Usage

To run the script, execute:

```bash
python ./scripts/heatmap_generator.py
```

#### Key Functionalities

1. **Attempt Range**: The script operates within a range of 'attempts' defined by the variable `attempt_range`.

2. **Softening Calculations**: It calculates a range of softening values using the array `generated_softenings`.

3. **Memory and Domain Parameters**: Example usage indicates that the script considers a range of values for parameters like `MULTIPLEDOMAINS` and `MemSize`.

4. **Heatmap Generation**: Utilizes matplotlib to generate heatmaps based on the simulation data, which can include different parameters and their corresponding effects on the simulation.

#### Additional Notes

- The script makes use of numpy for efficient numerical calculations, especially for operations involving arrays.
- A provision for adding an additional amount to the zero runtime log (`zero_runtime_log_addition`) is present, allowing for more accurate heatmap representations.

## Initial Condition Scripts

### snapshottimes_generator.py

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

## Other Scripts

### `niagara_push.sh`

#### Description

The `niagara_push.sh` script is a Bash utility for transferring an Initial Condition (IC) file to a remote server, specifically Niagara. The script runs an HDF5 IC generator, then uses `rsync` to move the IC file to the Niagara server.

#### Usage

To execute the script, navigate to the root directory and run:

```bash
./scripts/niagara_push.sh
```

#### Key Functionalities

1. **Server Configuration**: The script specifies server details like the user, server address, and destination folder.

2. **IC Generation**: Runs a Python script, `hdf5zelgenglass.py`, to generate an HDF5 IC file.

3. **File Transfer**: Utilizes the `rsync` command to transfer the generated IC file (`IC.hdf5`) to the specified server and folder.

#### Additional Notes

- The script relies on pre-configured server details and does not have error-handling mechanisms.
- It's designed to operate specifically with the Niagara server and the HDF5 IC file format.

### `snapshottimes_generator.py`

#### Description

The `snapshottimes_generator.py` script is a Python utility that generates a geometric sequence of snapshot times between a given start time and end time. The script utilizes the `numpy` and `scipy` libraries for numerical operations and statistical functions.

#### Usage

To run the script, navigate to the root directory and execute:

```bash
python ./scripts/snapshottimes_generator.py
```

#### Key Functionalities

1. **Snapshot Time Calculation**: Generates a geometric sequence of snapshot times using the `numpy` `logspace` function between a given start time (`t1`) and end time (`t2`).

2. **File Writing**: Writes the generated snapshot times to a file specified by the user.

3. **Normal Distribution Fitting**: Utilizes the `scipy.stats` `norm` and `erf` functions for normal distribution fitting.

4. **Customizable Parameters**: Allows customization of start time (`t1`), end time (`t2`), and the number of snapshots (`n`).

#### Additional Notes

- The script provides a set of helper functions to write snapshot times to a file and generate geometric snapshot times.
- It is designed to operate with specific naming conventions and directory structures.
- There is no error-handling mechanism in place, so the user should ensure correct configurations.
- The script is intended for use within this specific project's ecosystem and may require modifications for broader applications.
