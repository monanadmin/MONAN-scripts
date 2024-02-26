#module purge command doesn't working correctly 
module purge
export MODULEPATH=/usr/share/Modules/modulefiles:/etc/modulefiles:/scratch/app/modulos

module load sequana/current
module load netcdf/4.9.2_openmpi-4.1.6_gnu_sequana
module load pnetcdf/1.12.3_openmpi-4.1.6_gnu_sequana
#module unload openmpi/gnu/2.0.4.2_sequana pnetcdf/1.10_openmpi-2.0_gnu_sequana

# Preencher os caminhos abaixo com o comando module show pacote:
export PNETCDF=/scratch/app_sequana/pnetcdf/1.12.3_openmpi-4.1.6_gnu
export NETCDF=/scratch/app_sequana/netcdf/4.9.2

module list

export OMP_NUM_THREADS=1
export INIT_ATM_PART=sequana_cpu_dev

