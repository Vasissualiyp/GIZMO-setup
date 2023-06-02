This suite is used to automatically setup gizmo on Niagara and Sunnyvale clusters.

## gizmo_setup.sh

This bash script will clone the private bitbucket GIZMO repo and edit Makefile and Makefile.sys appropriately. You don't have to edit those now.
The Makefile edit also allows gizmo to run on starq.

It will then copy TREECOOL into the working directory. It also will create the Config.sh file with most widely usef flags and then open Config.sh in vim.

## autosub.sh

This script automatically will name the parameters file and job submission scripts and copy them to the working directory. 
It will also automatically determine and accordingly edit these files to work with Niagara/starq.

If you wish to edit the job submission script/parameters file, edit them in the template folder. run.sh is for Niagara, run-starq.sh is for starq.

The autosub script then submits the jobs. The results will be located at the output/ folder, with the current date and attempt in the folder's name.
For instance, search for output/2023/12/24:1/ gives the 1st attempt on Dec 24th, 2023.

## snapshottimes_generator.py

This python code will generate the snapshot times for increasing frequency (i.e. 1, 2, 2.5, 2.75, 2.875 etc.)
