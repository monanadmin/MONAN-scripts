#module purge command doesn't working correctly
module purge
export MODULEPATH=/usr/share/Modules/modulefiles:/etc/modulefiles:/scratch/app/modulos
module load sequana/current
module load netcdf/4.9.2_openmpi-4.1.6_gnu_sequana
module list

