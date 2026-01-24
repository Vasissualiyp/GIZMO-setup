#!/bin/bash
#SBATCH --nodes=3
##SBATCH -p debug
#SBATCH --account=rrg-rbond-ac
##SBATCH --account=rrg-murray-ac
#SBATCH --ntasks-per-node=192
#SBATCH	--time=24:00:00
##SBATCH	--time=1:00:00
##SBATCH --job-name=GIZMO_m12b_FIRE3
##SBATCH --output=gizmo_m12b_fire3.txt
##SBATCH --dependency=afterany:14592839
#SBATCH --mail-type=ALL

cd $SLURM_SUBMIT_DIR

#module load NiaEnv/2018a intel/2018.2 gsl/2.4 intelmpi/2018.2 hdf5/1.8.20 anaconda2 mercurial
module load StdEnv/2023 gcc/12.3 openmpi/4.1.5 fftw-mpi/3.3.10 gsl/2.7 hdf5/1.14.2


export OMP_NUM_THREADS=1

fire_name="$1"
restart_flag="$2"
chain_num="$3"

gizmo_dir="./gizmo_jeans_refinement"
logs_dir="logfiles/jeans_refinement"
#params_file="./music_run.params"
#params_file="./fire_parameters_shivan.txt"
#params_file="./m12i_params.txt"
#params_file="./params_split/$fire_name.txt"
params_file="./params_jeans_refinement/$fire_name.txt"
#params_file="./fire_parameters_shivan_restart.txt"
mkdir -p "$logs_dir"
output_file="$logs_dir/${fire_name}_$chain_num.out"
outdir=$(grep -i "^OutputDir" "$params_file" | awk '{print $2}')
mkdir -p "$outdir" || echo "Output directory already exists"


# Compiling GIZMO
#cd $gizmo_dir; make clean; make -j20
#cd $SLURM_SUBMIT_DIR

# Running GIZMO
#mpirun "$gizmo_dir/GIZMO_FIRE3" "$params_file" 0 > "$output_file"
#mpirun "$gizmo_dir/GIZMO_split_${fire_name}" "$params_file" "$restart_flag" > "$output_file"
mpirun "$gizmo_dir/GIZMO" "$params_file" "$restart_flag" > "$output_file"
