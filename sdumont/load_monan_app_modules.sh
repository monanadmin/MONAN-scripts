module purge
module load pnetcdf/1.12_openmpi-4.1.4_gnu
module load netcdf/4.9_openmpi-4.1.4_gnu
export NETCDF=/scratch/app/netcdf/4.9_openmpi-4.1.4_gnu
export PNETCDF=/scratch/app/pnetcdf/1.12_openmpi-4.1.4_gnu

module list

export OMP_NUM_THREADS=1

