#!/bin/bash

# TODO list:
# - CR: unificar todos exports em load_monan_app_modules.sh
# - DE: Alterar script de modo a poder executar novamente com os diretórios limpos e não precisar baixar os dados novamente
# - DE: Criar função para mensagem

export DIRroot=$(pwd)
export DATA_VERSION="0.2.2"
export DIRMONAN=${DIRroot}/MONAN
export DIRMONAN_ORI=${DIRroot}/MONAN_ori  # will override scripts at MONAN
export DIRDADOS=/mnt/beegfs/monan/dados/MONAN_v${DATA_VERSION} 
export GREEN='\033[1;32m'  # Green
export RED='\033[1;31m'    # Red
export NC='\033[0m'        # No Color
./load_monan_app_modules.sh


#----------------------------------

mkdir -p ${DIRMONAN}/logs 
mkdir -p ${DIRMONAN}/namelist 
mkdir -p ${DIRMONAN}/tar

if [ ! -d "${DIRMONAN}/testcase" ]; then

  mkdir -p ${DIRMONAN}/testcase/scripts
  echo -e  "${GREEN}==>${NC} Copying and decompressing testcase data... \n"
  tar -xzf ${DIRDADOS}/MONAN_testcase_v${DATA_VERSION}.tgz -C ${DIRroot}

  echo -e  "${GREEN}==>${NC} Copyings scripts from MONAN_ori to MONAN testcase script folders... \n"
  cp -rf ${DIRMONAN_ORI}/testcase/scripts/* ${DIRMONAN}/testcase/scripts/

else
  echo -e  "${GREEN}==>${NC} WARNING: All testcase data from repository at ${DIRMONAN_ORI}/testcase/scripts and all testcase data from ${DIRDADOS}/MONAN_testcase.v${DATA_VERSION}.tgz will not be updated at working folder ${DIRMONAN}. Remove ${DIRMONAN}/testcase folder to update.\n"
fi

if [ ! -d "${DIRMONAN}/data" ]; then

  echo -e  "${GREEN}==>${NC} Copying and decompressing all data for preprocessing... \n"
  echo -e  "${GREEN}==>${NC} It may take several minutes...\n"
  tar -xzf ${DIRDADOS}/MONAN_data_v${DATA_VERSION}.tgz -C ${DIRMONAN}

else
  echo -e  "${GREEN}==>${NC} WARNING: All data from ${DIRDADOS}/MONAN_data_v${DATA_VERSION}.tgz will not be updated at dir ${DIRMONAN}/data . Delete ${DIRMONAN}/data folder to update.\n"
fi

echo -e  "${GREEN}==>${NC} Creating make_static.sh for submiting init_atmosphere...\n"
cd ${DIRMONAN}/testcase/scripts
${DIRMONAN}/testcase/scripts/static.sh ERA5 1024002



echo -e  "${GREEN}==>${NC} Executing sbatch make_static.sh...\n"
cd ${DIRMONAN}/testcase/runs/ERA5/static
sbatch --wait make_static.sh

if [ ! -e x1.1024002.static.nc ]; then
  echo -e  "\n${RED}==>${NC} ***** ATTENTION *****\n"	
  echo -e  "${RED}==>${NC} Static phase fails ! Check logs at ${DIRMONAN}/testcase/runs/ERA5/static/logs . Exiting script. \n"
  exit -1
fi



echo -e  "${GREEN}==>${NC} Creating submition scripts degrib, atmosphere_model...\n"
cd ${DIRMONAN}/testcase/scripts
${DIRMONAN}/testcase/scripts/run_monan_gnu_egeon.bash ERA5 2021010100



echo -e  "${GREEN}==>${NC} Submiting degrib_exe.sh...\n"
mkdir -p ${HOME}/local/lib64
cp -f /usr/lib64/libjasper.so* ${HOME}/local/lib64
cp -f /usr/lib64/libjpeg.so* ${HOME}/local/lib64
cd ${DIRMONAN}/testcase/runs/ERA5/2021010100/wpsprd/
sbatch --wait degrib_exe.sh

files_ungrib=("LSM:1979-01-01_00" "GEO:1979-01-01_00" "FILE:2021-01-01_00" "FILE2:2021-01-01_00" "FILE3:2021-01-01_00")
for file in "${files_ungrib[@]}"; do
  if [[ ! -e "${file}" ]]; then
    echo -e  "\n${RED}==>${NC} ***** ATTENTION *****\n"	  
    echo -e  "${RED}==>${NC} Degrib fails ! At least the file ${file} was not generated at ${DIRMONAN}/testcase/runs/ERA5/2021010100/wpsprd/. \n"
    echo -e  "${RED}==>${NC} Check logs at ${DIRMONAN}/testcase/runs/ERA5/2021010100/logs . Exiting script. \n"
    exit -1
  fi
done



echo -e  "${GREEN}==>${NC} Submiting InitAtmos_exe.sh...\n"
cd ${DIRMONAN}/testcase/runs/ERA5/2021010100
sbatch --wait InitAtmos_exe.sh

if [ ! -e x1.1024002.init.nc ]; then
  echo -e  "\n${RED}==>${NC} ***** ATTENTION *****\n"	
  echo -e  "${RED}==>${NC} Init Atmosphere phase fails ! Check logs at ${DIRMONAN}/testcase/runs/ERA5/2021010100/logs . Exiting script.\n"
  exit -1
fi

echo -e  "${GREEN}==>${NC} Script ${0} completed. \n"

exit
