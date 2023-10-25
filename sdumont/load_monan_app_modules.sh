#module purge
module load sequana/current
module load openmpi/gnu/4.1.4_sequana
module load pnetcdf/1.10_openmpi-2.0_gnu_sequana
module load netcdf/4.6_openmpi-2.0_gnu_sequana
module unload openmpi/gnu/2.0.4.2_sequana

export PNETCDF=/scratch/app/pnetcdf/1.10_openmpi-2.0_gnu
export NETCDF=/scratch/app/netcdf/4.6_openmpi-2.0_gnu

module list

export OMP_NUM_THREADS=1

