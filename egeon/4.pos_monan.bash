#!/bin/bash

export DIRroot=$(pwd)
export DIRMPAS=${DIRroot}/MPAS
export DIRMPAS_ORI=${DIRroot}/MPAS_ori
export MPAS_EXEC_DIR=${DIRroot}/MPAS/exec
#export DIRMPASSCRIPTS=${DIRMPAS}/testcase/scripts
#export DIRDADOS=/mnt/beegfs/monan/dados/MPAS_v8.0.1 

export GREEN='\033[1;32m'  # Green
export NC='\033[0m'        # No Color

module load netcdf 
module load netcdf-fortran 
module load cdo-2.0.4-gcc-9.4.0-bjulvnd
module load opengrads-2.2.1

# start post processing

echo ""
echo -e  "${GREEN}==>${NC} Initiating post processing...\n"
mkdir -p ${DIRMPAS}/testcase/runs/ERA5/2021010100/postprd

# copy convert_mpas from MPAS/exec to testcase
cd ${DIRMPAS}/testcase/runs/ERA5/2021010100/postprd
rm -f ${DIRMPAS}/testcase/runs/ERA5/2021010100/postprd/convert_mpas
ln -s ${MPAS_EXEC_DIR}/convert_mpas ${DIRMPAS}/testcase/runs/ERA5/2021010100/postprd/

# copy from repository to testcase and runs /ngrid2latlon.sh
cp ${DIRMPAS_ORI}/testcase/scripts/ngrid2latlon.sh ${DIRMPAS}/testcase/runs/ERA5/2021010100/postprd/ngrid2latlon.sh
${DIRMPAS}/testcase/runs/ERA5/2021010100/postprd/ngrid2latlon.sh 

# copy from repository to testcase and runs prec.gs
cp ${DIRMPAS_ORI}/testcase/scripts/prec.gs ${DIRMPAS}/testcase/runs/ERA5/2021010100/postprd/prec.gs
grads -bpcx "run '${DIRMPAS}'/testcase/runs/ERA5/2021010100/postprd/prec.gs"  

cdo hourmean surface.nc mean.nc

exit
