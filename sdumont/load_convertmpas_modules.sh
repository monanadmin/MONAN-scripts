#module purge command doesn't working correctly
. ./unloadAllModules.sh
module load sequana/current
module load netcdf/4.6_openmpi-2.0_gnu_sequana
module list

