#module purge command doesn't working correctly
#. ./unloadAllModules.sh
module purge
export MODULEPATH=/usr/share/Modules/modulefiles:/etc/modulefiles:/scratch/app/modulos
module load sequana/current
module load netcdf/4.6_openmpi-2.0_gnu_sequana
module list

