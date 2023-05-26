#!/bin/bash
#SBATCH --nodes=4
#SBATCH --ntasks-per-node=40
#SBATCH	--time=1:00:00
#SBATCH --job-name=
#SBATCH --output=
#SBATCH --mail-type=FAIL

cd $SLURM_SUBMIT_DIR

module load intel intelmpi gsl hdf5 fftw

mpirun ./gizmo/GIZMO ./zel.params
