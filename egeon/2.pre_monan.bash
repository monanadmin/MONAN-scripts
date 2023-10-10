#!/bin/bash

export DIRroot=$(pwd)
export DIRMPAS=${DIRroot}/MPAS
export DIRMPAS_ORI=${DIRroot}/MPAS_ori  # will override scripts at MPAS
export DIRDADOS=/mnt/beegfs/monan/dados/MPAS_v8.0.1 
export GREEN='\033[1;32m'  # Green
export NC='\033[0m'        # No Color
./load_monan_app_modules.sh


# TODO list:
# - CR: unificar todos exports em load_monan_app_modules.sh
# - DE: Alterar script de modo a poder executar novamente com os diretórios limpos e não precisar baixar os dados novamente
# - DE: Criar função para mensagem

#----------------------------------

mkdir -p ${DIRMPAS}/logs 
mkdir -p ${DIRMPAS}/namelist 
mkdir -p ${DIRMPAS}/tar



echo -e  "${GREEN}==>${NC} Copying and decompressing testcase data... \n"
tar -xzf ${DIRDADOS}/MPAS_testcase.v1.0.tgz -C ${DIRroot}

echo -e  "${GREEN}==>${NC} Copyings scripts from MPAS_ori to MPAS testcase script folders... \n"
cp -rf ${DIRMPAS_ORI}/testcase/scripts/* ${DIRMPAS}/testcase/scripts/

echo -e  "${GREEN}==>${NC} Copying and decompressing all data for preprocessing... \n"
echo -e  "${GREEN}==>${NC} It may take several minutes...\n"
tar -xzf ${DIRDADOS}/MPAS_data_v1.0_ADDED_ERA5_INVARIANT.tgz -C ${DIRMPAS}

echo -e  "${GREEN}==>${NC} Creating make_static.sh for submiting init_atmosphere...\n"
cd ${DIRMPAS}/testcase/scripts
${DIRMPAS}/testcase/scripts/static.sh ERA5 1024002



echo -e  "${GREEN}==>${NC} Executing sbatch make_static.sh...\n"
cd ${DIRMPAS}/testcase/runs/ERA5/static
sbatch --wait make_static.sh

if [ ! -e x1.1024002.static.nc ]; then
  echo -e  "\n${GREEN}==>${NC} ***** ATTENTION *****\n"	
  echo -e  "${GREEN}==>${NC} Static phase fails ! Check logs at ${DIRMPAS}/testcase/runs/ERA5/static/logs . Exiting script. \n"
  exit -1
fi



echo -e  "${GREEN}==>${NC} Creating submition scripts degrib, atmosphere_model...\n"
cd ${DIRMPAS}/testcase/scripts
${DIRMPAS}/testcase/scripts/run_mpas_gnu_egeon.bash ERA5 2021010100



echo -e  "${GREEN}==>${NC} Submiting degrib_exe.sh...\n"
mkdir -p ${HOME}/local/lib64
cp -f /usr/lib64/libjasper.so* ${HOME}/local/lib64
cp -f /usr/lib64/libjpeg.so* ${HOME}/local/lib64
cd ${DIRMPAS}/testcase/runs/ERA5/2021010100/wpsprd/
sbatch --wait degrib_exe.sh

files_ungrib=("LSM:1979-01-01_00" "GEO:1979-01-01_00" "FILE:2021-01-01_00" "FILE2:2021-01-01_00" "FILE3:2021-01-01_00")
for file in "${files_ungrib[@]}"; do
  if [[ ! -e "${file}" ]]; then
    echo -e  "\n${GREEN}==>${NC} ***** ATTENTION *****\n"	  
    echo -e  "${GREEN}==>${NC} Degrib fails ! At least the file ${file} was not generated at ${DIRMPAS}/testcase/runs/ERA5/2021010100/wpsprd/. \n"
    echo -e  "${GREEN}==>${NC} Check logs at ${DIRMPAS}/testcase/runs/ERA5/2021010100/logs . Exiting script. \n"
    exit -1
  fi
done



echo -e  "${GREEN}==>${NC} Submiting InitAtmos_exe.sh...\n"
cd ${DIRMPAS}/testcase/runs/ERA5/2021010100
sbatch --wait InitAtmos_exe.sh

if [ ! -e x1.1024002.init.nc ]; then
  echo -e  "\n${GREEN}==>${NC} ***** ATTENTION *****\n"	
  echo -e  "${GREEN}==>${NC} Init Atmosphere phase fails ! Check logs at ${DIRMPAS}/testcase/runs/ERA5/2021010100/logs . Exiting script.\n"
  exit -1
fi

exit
