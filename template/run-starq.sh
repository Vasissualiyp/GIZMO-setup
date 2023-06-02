#!/bin/bash -l
#PBS -l nodes=1:ppn=128
#PBS -l walltime=1:00:00
#PBS -r n
#PBS -j oe
#PBS -q starq

# NOTE: workq only allows nodes=1 and ppn<=8
# Load your modules
# if you use module purge, make sure to load the maui and torque modules
# e.g.,
# module purge

#module load maui torque

#module load gcc/7.3.0 python/2.7.14
#module load gcc/9.3.0 python/3.8.2

module purge
#module load intel intelmpi gsl/2.7.1-intel-19.1.3 hdf5/1.12.1-intel
module load gcc/11.2.0 openmpi/4.1.2-ucx gsl/2.7.1 hdf5/1.12.1-ucx fftw/3.3.10-openmpi-ucx 


# go to your working directory containing the batch script, code and data
cd $PBS_O_WORKDIR

#echo $PBS_O_WORKDIR
#echo $PATH

cd gizmo
make clean
make -j 10
cd ..

export OMP_NUM_THREADS=128

#mpirun -np 128 ./GIZMO gizmo_parameters.txt > dummy.out
mpirun -np 128 ./gizmo/GIZMO zel.params 

