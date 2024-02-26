#!/bin/bash

# TODO list:
# - CR: unificar todos exports em load_monan_app_modules.sh
# - DE: Alterar script de modo a poder executar novamente com os diretórios limpos e não precisar baixar os dados novamente
# - DE: Criar função para mensagem

export DIRroot=$(pwd)
export DIRMONAN=${DIRroot}/MONAN
export DIRMONAN_ORI=${DIRroot}/MONAN_ori  # will override scripts at MONAN
#export DIRDADOS=pesquisa/dmdcc/monan/MONAN_v0.1.0
export DIRDADOS=/scratch/cenapadrjsd/rpsouto/sequana/projetos/monan
export FTPADD=http://ftp.cptec.inpe.br
export GREEN='\033[1;32m'  # Green
export RED='\033[1;31m'    # Red
export NC='\033[0m'        # No Color
. ./load_monan_app_modules.sh


#----------------------------------

mkdir -p ${DIRMONAN}/logs 
mkdir -p ${DIRMONAN}/namelist 
mkdir -p ${DIRMONAN}/tar



echo -e  "${GREEN}==>${NC} Copying and decompressing testcase data... \n"
# Temporariamente, enquanto desenv:----------------------------------------------v
#wget ${FTPADD}/${DIRDADOS}/MONAN_testcase_v1.0.tgz 
#CR: TODO: verificar se o wget baixou corretamente o dado antes de destargear:
#tar -xzf ./MONAN_testcase_v1.0.tgz -C ${DIRroot}
if [ ! -s ${DIRDADOS}/MONAN_testcase_v1.0.tgz ] 
then
   echo "dado nao existe no /tmp/${DIRDADOS}/MONAN_testcase_v1.0.tgz"
   exit
fi
tar -xzf ${DIRDADOS}/MONAN_testcase_v1.0.tgz -C ${DIRroot}
# Temporariamente, enquanto desenv:----------------------------------------------^


echo -e  "${GREEN}==>${NC} Copyings scripts from MONAN_ori to MONAN testcase script folders... \n"
cp -rf ${DIRMONAN_ORI}/testcase/scripts/* ${DIRMONAN}/testcase/scripts/

echo -e  "${GREEN}==>${NC} Copying and decompressing all data for preprocessing... \n"
echo -e  "${GREEN}==>${NC} It may take several minutes...\n"
#CR: TODO: inserir opcao "timestamping" no wget:  baixa o arq somente sei verificar que o arq ja existe no dir local. (testar)

# Temporariamente, enquanto desenv:----------------------------------------------v
#wget ${FTPADD}/${DIRDADOS}/MONAN_data_v1.0.tgz
#CR: TODO: verificar se o wget baixou corretamente o dado antes de destargear:
#CR: TODO: incluir o dir MONAN dentro do tar MONAN_data_v1.0.tgz para fim de padronizacao.
#tar -xzf ${DIRDADOS}/MONAN_data_v1.0.tgz -C ${DIRMONAN}
if [ ! -s /tmp/${DIRDADOS}/MONAN_data_v1.0.tgz ] 
then
   echo "dado nao existe no /tmp/${DIRDADOS}/MONAN_data_v1.0.tgz"
   exit
fi
tar -xzf /tmp/${DIRDADOS}/MONAN_data_v1.0.tgz -C ${DIRMONAN} > /dev/null &
PID=$!
i=1
sp="/-\|"
echo -n ' '
while [ -d /proc/$PID ]
do
   sleep 0.1
   printf "\b${sp:i++%${#sp}:1}"
done
# Temporariamente, enquanto desenv:----------------------------------------------^


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

#CR: paramos aqui (CR+BIDU):
exit

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
