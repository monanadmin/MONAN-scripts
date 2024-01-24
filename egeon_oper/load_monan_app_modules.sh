module purge
module load ohpc
module unload openmpi4
module load phdf5
module load netcdf
module load netcdf-fortran
module load mpich-4.0.2-gcc-9.4.0-gpof2pv
module load hwloc
module list

export OMP_NUM_THREADS=1
export OMPI_MCA_btl_openib_allow_ib=1
export OMPI_MCA_btl_openib_if_include="mlx5_0:1"
export PMIX_MCA_gds=hash

export NETCDF=/mnt/beegfs/monan/libs/netcdf
export PNETCDF=/mnt/beegfs/monan/libs/PnetCDF

MPI_PARAMS="-iface ib0 -bind-to core -map-by core"
export MKL_NUM_THREADS=1
export I_MPI_DEBUG=5
export MKL_DEBUG_CPU_TYPE=5
export I_MPI_ADJUST_BCAST=12 ## NUMA aware SHM-Based (AVX512)

# variables for MONAN-scripts/egeon_oper repository
export DIRroot=$(pwd)
export DIRMONAN=${DIRroot}/MONAN
export DIRMONAN_SCR=${DIRroot}/scripts  # will override scripts at MONAN
export DIRMONAN_NML=${DIRroot}/namelist  # will override namelist at MONAN
export DIRMONAN_NCL=${DIRroot}/scripts/NCL  # will override NCL at MONAN
export DIRDADOS=/mnt/beegfs/monan/dados/MONAN_v0.1.0

# variables for MONAN/testcase dir, and static/run_monan_gnu.egeon scripts
export BASEDIR=${DIRMONAN}/testcase
export DATADIR=${BASEDIR}/data
export TBLDIR=${BASEDIR}/tables
export NMLDIR=${BASEDIR}/namelist
export GEODATA=${BASEDIR}/data/WPS_GEOG/
export EXECPATH=${BASEDIR}/../exec
export RUNDIR=${BASEDIR}/runs
export SCRDIR=${BASEDIR}/scripts

export GREEN='\033[1;32m'  # Green
export RED='\033[1;31m'    # Red
export NC='\033[0m'        # No Color
