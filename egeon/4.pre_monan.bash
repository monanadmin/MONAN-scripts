#!/bin/bash

#if [ $# -ne 1 ]
#then
#   echo ""
#   echo "${0} [root_dir]"
#   echo ""
#   echo "root_dir :: root directory where you want to intall MPAS-set."
#   echo ""
#   exit
#fi

#DIRroot=${1}
export DIRroot=$(pwd)
export DIRMPAS=${DIRroot}/MPAS
export DIRMPAS_ORI=${DIRroot}/MPAS_ori  # will override scripts at MPAS

export DIRMPASEXECS=${DIRMPAS}/src/MPAS-Model_${vlabel}_egeon.gnu940

export DIRDADOS=/mnt/beegfs/monan/dados/MPAS_v8.0.1 
export WPSDIR=$(spack location -i wps@4.3.1%gcc@9.4.0)

export GREEN='\033[1;32m'  # Green
export NC='\033[0m'        # No Color



#----------------------------------


mkdir -p ${DIRMPAS}/exec 
mkdir -p ${DIRMPAS}/logs 
mkdir -p ${DIRMPAS}/namelist 
mkdir -p ${DIRMPAS}/src
mkdir -p ${DIRMPAS}/tar
 
echo ""
echo -e  "${GREEN}==>${NC} Copying ungrib.exe from WPS dir...\n"
cp -f ${WPSDIR}/ungrib.exe ${DIRMPAS}/exec


echo ""
echo -e  "${GREEN}==>${NC} It takes several minutes...\n"
#cd ${DIRMPAS}/tar
echo -e  "${GREEN}==>${NC} Copying and decompressing testcase data... \n"
tar -xzf ${DIRDADOS}/MPAS_testcase.v1.0.tgz -C ${DIRroot}
echo -e  "${GREEN}==>${NC} Copyings scripts from MPAS_ori to MPAS testcase script folders... \n"
cp -rfv ${DIRMPAS_ORI}/testcase/scripts/* ${DIRMPAS}/testcase/scripts/
echo -e  "${GREEN}==>${NC} Copying and decompressing all data for preprocessing... \n"
tar -xzf ${DIRDADOS}/MPAS_data_v1.0_ADDED_ERA5_INVARIANT.tgz -C ${DIRMPAS}



echo ""
echo -e  "${GREEN}==>${NC} Creating make_static.sh for submiting init_atmosphere...\n"
cd ${DIRMPAS}/testcase/scripts
${DIRMPAS}/testcase/scripts/static.sh ERA5 1024002

echo ""
echo -e  "${GREEN}==>${NC} Executing sbatch make_static.sh...\n"
#CR: TO DO: verificar arquivos de saida se foram gerados corretamente
cd ${DIRMPAS}/testcase/runs/ERA5/static
sbatch --wait make_static.sh


echo ""
echo -e  "${GREEN}==>${NC} Creating submition scripts degrib, atmosphere_model...\n"
cd ${DIRMPAS}/testcase/scripts
${DIRMPAS}/testcase/scripts/run_mpas_gnu_egeon.bash ERA5 2021010100


echo ""
echo -e  "${GREEN}==>${NC} Submiting degrib_exe.sh...\n"
#CR: TO DO: verificar arquivos de saida se foram gerados corretamente
mkdir -p ${HOME}/local/lib64
cp -f /usr/lib64/libjasper.so* ${HOME}/local/lib64
cd ${DIRMPAS}/testcase/runs/ERA5/2021010100/wpsprd/
sbatch --wait degrib_exe.sh


echo ""
echo -e  "${GREEN}==>${NC} Submiting InitAtmos_exe.sh...\n"
#CR: TO DO: verificar arquivos de saida se foram gerados corretamente
cd ${DIRMPAS}/testcase/runs/ERA5/2021010100
sbatch --wait InitAtmos_exe.sh



exit
