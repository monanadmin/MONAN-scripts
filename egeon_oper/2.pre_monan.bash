#!/bin/bash

# TODO list:
# - CR: unificar todos exports em load_monan_app_modules.sh
# - DE: Alterar script de modo a poder executar novamente com os diretórios limpos e não precisar baixar os dados novamente
# - DE: Criar função para mensagem

export DIRroot=$(pwd)
export DIRMONAN=${DIRroot}/MONAN
export DIRMONAN_SCR=${DIRroot}/scripts  # will override scripts at MONAN
export DIRMONAN_NML=${DIRroot}/namelist  # will override namelist at MONAN
export DIRMONAN_NCL=${DIRroot}/scripts/NCL  # will override NCL at MONAN
export DIRDADOS=/mnt/beegfs/monan/dados/MONAN_v0.1.0 
export GREEN='\033[1;32m'  # Green
export RED='\033[1;31m'    # Red
export NC='\033[0m'        # No Color
./load_monan_app_modules.sh


#----------------------------------

mkdir -p ${DIRMONAN}/logs 
mkdir -p ${DIRMONAN}/namelist 
mkdir -p ${DIRMONAN}/tar



echo -e  "${GREEN}==>${NC} Copying and decompressing testcase data... \n"
tar -xzf ${DIRDADOS}/MONAN_testcase_GFS.v1.0.tgz -C ${DIRroot}

echo -e  "${GREEN}==>${NC} Copyings scripts from repository to MONAN testcase script folders... \n"
cp -rf ${DIRMONAN_SCR}/* ${DIRMONAN}/testcase/scripts/

echo -e  "${GREEN}==>${NC} Copyings scripts from repository to MONAN testcase namelist folders... \n"
cp -rf ${DIRMONAN_NML}/* ${DIRMONAN}/testcase/namelist/

echo -e  "${GREEN}==>${NC} Copyings scripts from repository to MONAN testcase NCL folders... \n"
cp -rf ${DIRMONAN_NCL}/* ${DIRMONAN}/testcase/NCL/

echo -e  "${GREEN}==>${NC} Copying and decompressing all data for preprocessing... \n"
echo -e  "${GREEN}==>${NC} It may take several minutes...\n"
tar -xzf ${DIRDADOS}/MONAN_data_GFS_v1.0.tgz -C ${DIRMONAN}
tar -xzf ${DIRDADOS}/MONAN_data_v1.0.tgz -C ${DIRMONAN}

echo -e  "${GREEN}==>${NC} Creating make_static.sh for submiting init_atmosphere...\n"
cd ${DIRMONAN}/testcase/scripts
${DIRMONAN}/testcase/scripts/static.sh GFS 1024002



echo -e  "${GREEN}==>${NC} Executing sbatch make_static.sh...\n"
cd ${DIRMONAN}/testcase/runs/GFS/static
sbatch --wait make_static.sh

if [ ! -e x1.1024002.static.nc ]; then
  echo -e  "\n${RED}==>${NC} ***** ATTENTION *****\n"	
  echo -e  "${RED}==>${NC} Static phase fails ! Check logs at ${DIRMONAN}/testcase/runs/GFS/static/logs . Exiting script. \n"
  exit -1
fi



echo -e  "${GREEN}==>${NC} Creating submition scripts degrib, atmosphere_model...\n"
cd ${DIRMONAN}/testcase/scripts
${DIRMONAN}/testcase/scripts/run_monan_gnu_egeon.bash GFS 2021060100



echo -e  "${GREEN}==>${NC} Submiting degrib_exe.sh...\n"
mkdir -p ${HOME}/local/lib64
cp -f /usr/lib64/libjasper.so* ${HOME}/local/lib64
cp -f /usr/lib64/libjpeg.so* ${HOME}/local/lib64
cd ${DIRMONAN}/testcase/runs/GFS/2021060100/wpsprd/
sbatch --wait degrib_exe.sh

#files_ungrib=("LSM:1979-01-01_00" "GEO:1979-01-01_00" "FILE:2021-01-01_00" "FILE2:2021-01-01_00" "FILE3:2021-01-01_00")
files_ungrib=("GFS:2021-06-01_00")
for file in "${files_ungrib[@]}"; do
  if [[ ! -e "${file}" ]]; then
    echo -e  "\n${RED}==>${NC} ***** ATTENTION *****\n"	  
    echo -e  "${RED}==>${NC} Degrib fails ! At least the file ${file} was not generated at ${DIRMONAN}/testcase/runs/GFS/2021060100/wpsprd/. \n"
    echo -e  "${RED}==>${NC} Check logs at ${DIRMONAN}/testcase/runs/GFS/2021060100/logs . Exiting script. \n"
    exit -1
  fi
done



echo -e  "${GREEN}==>${NC} Submiting InitAtmos_exe.sh...\n"
cd ${DIRMONAN}/testcase/runs/GFS/2021060100
sbatch --wait InitAtmos_exe.sh

if [ ! -e x1.1024002.init.nc ]; then
  echo -e  "\n${RED}==>${NC} ***** ATTENTION *****\n"	
  echo -e  "${RED}==>${NC} Init Atmosphere phase fails ! Check logs at ${DIRMONAN}/testcase/runs/GFS/2021060100/logs . Exiting script.\n"
  exit -1
fi

echo -e  "${GREEN}==>${NC} Script ${0} completed. \n"

exit
