#!/bin/bash

export DIRroot=$(pwd)
export DIRMPAS=${DIRroot}/MPAS
export DIRMPASSRC=${DIRMPAS}/src
export DIRMPASEXECS=${DIRMPAS}/src/convert_mpas
export DIRMPASSCRIPTS=${DIRMPAS}/testcase/scripts
export DIRDADOS=/mnt/beegfs/monan/dados/MPAS_v8.0.1 

export GREEN='\033[1;32m'  # Green
export NC='\033[0m'        # No Color

module load netcdf 
module load netcdf-fortran 
module load cdo-2.0.4-gcc-9.4.0-bjulvnd
module load opengrads-2.2.1


# install convert_mpas

cd ${DIRMPASSRC}
git clone http://github.com/mgduda/convert_mpas.git
cd ${DIRMPASSRC}/convert_mpas
make clean
make  2>&1 | tee make.convert.output


# start post processing

echo ""
echo -e  "${GREEN}==>${NC} Initiating post processing...\n"

cd ${DIRMPAS}/testcase/runs/ERA5/2021010100/postprd

ln -s ${DIRMPASSRC}/convert_mpas/convert_mpas ${DIRMPAS}/testcase/runs/ERA5/2021010100/postprd/

${DIRMPAS}/testcase/runs/ERA5/2021010100/postprd/ngrid2latlon.sh 

grads -bpcx "run '${DIRMPAS}'/testcase/runs/ERA5/2021010100/postprd/prec.gs"  

cdo hourmean surface.nc mean.nc

exit
