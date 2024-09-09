#!/bin/bash

# TODO list:
# - CR: unificar todos exports em load_monan_app_modules.sh
# - DE: Alterar script de modo a poder executar novamente com os diretórios limpos e não precisar baixar os dados novamente
# - DE: Criar função para mensagem

export DIRroot=$(pwd)
export DIRMONAN=${DIRroot}/MONAN
export DIRMONAN_ORI=${DIRroot}/MONAN_ori  # will override scripts at MONAN
export DIRDADOS=./pesquisa/dmdcc/monan/MONAN_v0.1.0
export DIRDADOS_LOCAL=/scratch/cenapadrjsd/rpsouto/sequana/projetos/monan
export FTPADD=http://ftp.cptec.inpe.br
export GREEN='\033[1;32m'  # Green
export RED='\033[1;31m'    # Red
export NC='\033[0m'        # No Color

#----------------------------------

mkdir -p ${DIRMONAN}/logs 
mkdir -p ${DIRMONAN}/namelist 
mkdir -p ${DIRMONAN}/tar
  RES=1024002
  RES=40962

function dataPhase(){ # data part 
  echo ----------------    em function firstPart
  echo -e  "${GREEN}==>${NC} Copying and decompressing testcase data... \n"
  echo -e  "${GREEN}==>${NC}  and submit init_atmospere ... \n"
  # Temporariamente, enquanto desenv:----------------------------------------------v
  wget ${FTPADD}/${DIRDADOS}/MONAN_testcase_v1.0.tgz 
  #CR: TODO: verificar se o wget baixou corretamente o dado antes de destargear:
  comando="cp -f  ../../../rpsouto/sequana/projetos/monan/ungrib/ungrib.exe MONAN/exec/ungrib.exe"
  echo $comando; eval $comando
  cp  ../../../rpsouto/sequana/projetos/monan/ungrib/ungrib.exe MONAN/exec/ungrib_SD.exe
  if [ ! -s MONAN_testcase_v1.0.tgz ] 
  then
     echo "dado nao existe no MONAN_testcase_v1.0.tgz"
     #exit
  fi
  tar -xzf MONAN_testcase_v1.0.tgz -C ${DIRroot}
  # Temporariamente, enquanto desenv:----------------------------------------------^

  echo -e  "${GREEN}==>${NC} Copyings scripts from MONAN_ori to MONAN testcase script folders... \n"
  comando="cp -rf ${DIRMONAN_ORI}/testcase/scripts/* ${DIRMONAN}/testcase/scripts/"
  echo "em $(basename $0), $comando"; eval $comando

  echo -e  "${GREEN}==>${NC} Copying and decompressing all data for preprocessing... \n"
  echo -e  "${GREEN}==>${NC} It may take several minutes...\n"
  #CR: TODO: inserir opcao "timestamping" no wget:  baixa o arq somente sei verificar que o arq ja existe no dir local. (testar)

  # Temporariamente, enquanto desenv:----------------------------------------------v
  wget ${FTPADD}/${DIRDADOS}/MONAN_data_v1.0.tgz
  #CR: TODO: verificar se o wget baixou corretamente o dado antes de destargear:
  #CR: TODO: incluir o dir MONAN dentro do tar MONAN_data_v1.0.tgz para fim de padronizacao.
  if [ ! -s ${DIRDADOS_LOCAL}/MONAN_data_v1.0.tgz ] 
  then
     echo "dado nao existe no ${DIRDADOS_LOCAL}/MONAN_data_v1.0.tgz"
     #exit
  fi

  if [ -d MONAN/data ] 
  then
     echo "A pasta MONAN ja existe, originada do arquivo ${DIRDADOS_LOCAL}/MONAN_data_v1.0.tgz"
  else
     echo "A pasta MONAN ainda nao existe, descompactando arquivo ${DIRDADOS_LOCAL}/MONAN_data_v1.0.tgz"
     date
     time tar -xzf ${DIRDADOS_LOCAL}/MONAN_data_v1.0.tgz -C ${DIRMONAN} > /dev/null &
     PID=$!
     i=1
     sp="/-\|"
     echo -n ' '
     while [ -d /proc/$PID ]
     do
        sleep 0.1
        printf "\b${sp:i++%${#sp}:1}"
     done
     date
  fi
} #  function dataPhase

function 40962dataA(){

  comando="cp /scratch/cenapadrjsd/eduardo.garcia2/monan/$RES/x1.$RES.grid.nc                     ${DIRroot}/MONAN/testcase/data/meshes/"
  echo $comando; eval $comando

  comando="cp /scratch/cenapadrjsd/eduardo.garcia2/monan/$RES/x1.$RES.graph.info.part.$numNucleos ${DIRroot}/MONAN/testcase/namelist/"
  echo $comando; eval $comando

} # function 40962dataA(){

function 40962dataB(){

  comando="cp /scratch/cenapadrjsd/eduardo.garcia2/monan/$RES/static/namelist.init_atmosphere  ${DIRroot}/MONAN/testcase/runs/ERA5/static/; "
  #echo $comando; eval $comando

  comando="cp /scratch/cenapadrjsd/eduardo.garcia2/monan/$RES/static/streams.init_atmosphere   ${DIRroot}/MONAN/testcase/runs/ERA5/static/; "
  #echo $comando; eval $comando

  comando="cp /scratch/cenapadrjsd/eduardo.garcia2/monan/$RES/namelist.init_atmosphere  ${DIRroot}/MONAN/testcase/runs/ERA5/2021010100/; "
  echo $comando; eval $comando

  comando="cp /scratch/cenapadrjsd/eduardo.garcia2/monan/$RES/streams.init_atmosphere   ${DIRroot}/MONAN/testcase/runs/ERA5/2021010100/; "
  echo $comando; eval $comando

  comando="cp /scratch/cenapadrjsd/eduardo.garcia2/monan/$RES/namelist.atmosphere       ${DIRroot}/MONAN/testcase/runs/ERA5/2021010100/; "
  echo $comando; eval $comando

  comando="cp /scratch/cenapadrjsd/eduardo.garcia2/monan/$RES/streams.atmosphere        ${DIRroot}/MONAN/testcase/runs/ERA5/2021010100/; "
  echo $comando; eval $comando

} # function 40962dataB(){

function static (){

  # Temporariamente, enquanto desenv:----------------------------------------------^
  echo -e  "${GREEN}==>${NC} Creating make_static.sh for submiting static init_atmosphere...\n"
  echo -e  "${GREEN}==>${NC}    and data: streams.init_atmosphere namelist.init_atmosphere \n"
  cd ${DIRMONAN}/testcase/scripts
  echo PWD="$(pwd)"
  comando="${DIRMONAN}/testcase/scripts/static.sh ERA5 $RES"
  echo  $comando ; eval $comando
  comando="grep \"x1\" /scratch/cenapadrjsd/eduardo.garcia2/MONAN-scripts/sdumont/MONAN/testcase/runs/ERA5/static/*.init_atmosphere*"
  echo $comando ; eval $comando

  #read -p "esperando um ok!"
  echo -e  "${GREEN}==>${NC} Submiting sbatch make_static.sh...\n"
  cd ${DIRMONAN}/testcase/runs/ERA5/static
  pwd
  date
  comando="sbatch --wait make_static.sh"
  echo $comando; eval $comando
  date

  if [ ! -e x1.$RES.static.nc ]; then
    echo -e  "\n${RED}==>${NC} ***** ATTENTION *****\n"	
    echo -e  "${RED}==>${NC} Static phase fails ! Check logs at ${DIRMONAN}/testcase/runs/ERA5/static/logs . Exiting script. \n"
    #exit 1
  else
    echo -e  "${GREEN}==>${NC} Static phase finished ! Check logs at ${DIRMONAN}/testcase/runs/ERA5/static/logs.\n"
  fi

} #  end function static (){

function criarDataAndSLURMScripts (){
  echo -e  "${GREEN}==>${NC} Creating submition script to ungrib,          degrib_exe.sh \n"
  echo -e  "${GREEN}==>${NC} Creating submition script to init_atmosphere, Init_atmos.sh \n"
  echo -e  "${GREEN}==>${NC}    and data : streams.init_atmosphere namelist.init_atmosphere \n"
  echo -e  "${GREEN}==>${NC} Creating submition script to atmosphere,      monan_exe.sh  \n"
  echo -e  "${GREEN}==>${NC}    and data : streams.atmosphere namelist.atmosphere \n"
  cp -rf ${DIRMONAN_ORI}/testcase/scripts/* ${DIRMONAN}/testcase/scripts/
  cd ${DIRMONAN}/testcase/scripts

  if [ $RES -eq "40962" ] ; then
     sed -i '/RES=/a RES=40962' ${DIRMONAN}/testcase/scripts/run_monan.bash;
  fi

  comando="${DIRMONAN}/testcase/scripts/run_monan.bash ERA5 2021010100"
  echo "em $(basename $0), $comando"; eval $comando

  if [ $RES -eq "40962" ] ; then 40962dataB; fi
  echo "fim de criarDataAndSLURMScripts"

}

function degrib(){ # make_degrib
  echo ----------------    em function degrib
  HOME=$SCRATCH

  echo ----------------    submiting script : degrib_exe.sh  

  mkdir -p ${HOME}/local/lib64
  cp -f /usr/lib64/libjasper.so* ${HOME}/local/lib64
  cp -f /usr/lib64/libjpeg.so* ${HOME}/local/lib64

  cd ${DIRMONAN}/testcase/runs/ERA5/2021010100/wpsprd/

  echo -e  "${GREEN}==>${NC} Submiting degrib_exe.sh...\n"
  pwd
  date
  comando="sbatch --wait degrib_exe.sh"
  echo $comando ;  eval $comando
  date
#  return

  files_ungrib=("LSM:1979-01-01_00" "GEO:1979-01-01_00" "FILE:2021-01-01_00" "FILE2:2021-01-01_00" "FILE3:2021-01-01_00")
  for file in "${files_ungrib[@]}"; do
    if [[ ! -e "${file}" ]]; then
      echo -e  "\n${RED}==>${NC} ***** ATTENTION *****\n"	  
      echo -e  "${RED}==>${NC} Degrib fails ! At least the file ${file} was not generated at ${DIRMONAN}/testcase/runs/ERA5/2021010100/wpsprd/. \n"
      echo -e  "${RED}==>${NC} Check logs at ${DIRMONAN}/testcase/runs/ERA5/2021010100/logs . Exiting script. \n"
      #exit  1
    fi
  done
  echo -e  "${GREEN}==>${NC} Degrib finished ! Check logs at ${DIRMONAN}/testcase/runs/ERA5/2021010100/wpsprd/. \n"
} # function degrib(){

function initAtmos(){ # make_init_atmos
  echo ----------------    em function initAtmos
  echo -e  "${GREEN}==>${NC} Submiting script InitAtmos_exe.sh...\n"
  cd ${DIRMONAN}/testcase/runs/ERA5/2021010100
  pwd
  date
  comando="sbatch --wait InitAtmos_exe.sh"
  echo $comando;  eval $comando
  date
#  return
  if [ ! -e x1.$RES.init.nc ]; then
    echo -e  "\n${RED}==>${NC} ***** ATTENTION *****\n"	
    echo -e  "${RED}==>${NC} Init Atmosphere phase fails ! Check logs at ${DIRMONAN}/testcase/runs/ERA5/2021010100/logs . Exiting script.\n"
    #exit -1
  else
    echo -e  "${GREEN}==>${NC} Init Atmosphere phase finished ! Check logs at ${DIRMONAN}/testcase/runs/ERA5/2021010100/logs.\n"
  fi
  echo -e  "${GREEN}==>${NC} Script ${0} completed. \n"
} # function initAtmos

#shift
source ${DIRroot}/load_monan_app_modules.sh $compiler

#dataPhase  # testcase data phase, originals scripts  + ungrib

if [ $RES -eq "40962" ] ; then 40962dataA; fi

static #  static.sh e submit make_static.sh -> x1.$RES.static.nc

criarDataAndSLURMScripts  # run_monan.bash;

# commands below shows discretization adopted at initial condition and at model
comando="grep \"x1\" /scratch/cenapadrjsd/eduardo.garcia2/MONAN-scripts/sdumont/MONAN/testcase/runs/ERA5/2021010100/*.init_atmosphere"
echo $comando ; eval $comando
comando="grep \"x1\" /scratch/cenapadrjsd/eduardo.garcia2/MONAN-scripts/sdumont/MONAN/testcase/runs/ERA5/2021010100/*.atmosphere"
echo $comando ; eval $comando

degrib # submit degrid_exe.sh  -> directory wpsprd

initAtmos  # submit Init_atmos_exe.sh -> x1.$RES.init.nc
