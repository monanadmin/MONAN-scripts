#!/bin/bash
#-----------------------------------------------------------------------------#
#BOP
#
# !SCRIPT: pre_monan
#
# !DESCRIPTION: 
#        Script para preparar a rodada do MONAN
#        Realiza as seguintes tarefas:
#           o Cria topografia, land use e variáveis estáticas
#           o Ungrib os dados do GFS
#           o Interpola para grade do modelo
#           o Cria condicao inicial e de fronteria
#           o Cria scripts para rodar o modelo e o pos-processamento
#           o Integra o modelo MONAN
#           o Pos-processamento (netcdf para grib2, regrid latlon, crop)
#
# !CALLING SEQUENCE:
#
#     ./2.pre_monan.bash EXP_NAME RESOLUTION LABELI
#           o EXP_NAME   : Forcing: GFS
#           o RESOLUTION : 1024002  (24 km)
#           o LABELI     : Initial: date 2024010100
#           o FCST       : Forecast: 24, 36, 72, 84, etc. [hours] - not yet
#
# !REVISION HISTORY: 
#
# !REMARKS:
#
#EOP
#-----------------------------------------------------------------------------!
#EOC

# TODO list:
# - CR: unificar todos exports em load_monan_app_modules.sh
# - DE: Alterar script de modo a poder executar novamente com os diretórios limpos e não precisar baixar os dados novamente
# - DE: Criar função para mensagem


function usage(){
   sed -n '/^# !CALLING SEQUENCE:/,/^# !/{p}' ./2.pre_monan.bash | head -n -1
}

#
# Verificando argumentos de entrada
#

if [ $# -ne 3 ]; then
   usage
   exit 1
fi

#
# pegando argumentos
#
EXP=${1}
RES=${2}
LABELI=${3} 


#----------------------------------

. ./load_monan_app_modules.sh

  datai=${LABELI}
  echo ${datai}

  hh=${datai:8:2}

  # soma 24 horas de previsao - pode ser modificado dependendo da entrada das horas de previsao (aqui FST=24)
  dataf=`date -d "${datai:0:8} ${hh}:00 24 hours" +"%Y%m%d%H"`

  echo
  echo ${dataf}

export dataf=`date -d "${datai:0:8} ${hh}:00 24 hours" +"%Y%m%d%H"`

#----------------------------------

mkdir -p ${DIRMONAN}/logs 
mkdir -p ${DIRMONAN}/namelist 
mkdir -p ${DIRMONAN}/tar

#----------------------------------


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
tar -xzf ${DIRDADOS}/MONAN_data_v1.0.tgz -C ${DIRMONAN}

echo -e  "${GREEN}==>${NC} Creating make_static.sh for submiting init_atmosphere...\n"
cd ${DIRMONAN}/testcase/scripts
${DIRMONAN}/testcase/scripts/static.sh ${EXP} ${RES}



echo -e  "${GREEN}==>${NC} Executing sbatch make_static.sh...\n"
cd ${DIRMONAN}/testcase/runs/${EXP}/static
sbatch --wait make_static.sh

if [ ! -e x1.${RES}.static.nc ]; then
  echo -e  "\n${RED}==>${NC} ***** ATTENTION *****\n"	
  echo -e  "${RED}==>${NC} Static phase fails ! Check logs at ${DIRMONAN}/testcase/runs/${EXP}/static/logs . Exiting script. \n"
  exit -1
fi



echo -e  "${GREEN}==>${NC} Creating submition scripts degrib, atmosphere_model...\n"
cd ${DIRMONAN}/testcase/scripts
${DIRMONAN}/testcase/scripts/run_monan_gnu_egeon.bash ${EXP} ${LABELI}



echo -e  "${GREEN}==>${NC} Submiting degrib_exe.sh...\n"
mkdir -p ${HOME}/local/lib64
cp -f /usr/lib64/libjasper.so* ${HOME}/local/lib64
cp -f /usr/lib64/libjpeg.so* ${HOME}/local/lib64
cd ${DIRMONAN}/testcase/runs/${EXP}/${LABELI}/wpsprd/
sbatch --wait degrib_exe.sh

files_ungrib=("${EXP}:${LABELI:0:4}-${LABELI:4:2}-${LABELI:6:2}_${LABELI:8:2}")
for file in "${files_ungrib[@]}"; do
  if [[ ! -e "${file}" ]]; then
    echo -e  "\n${RED}==>${NC} ***** ATTENTION *****\n"	  
    echo -e  "${RED}==>${NC} Degrib fails ! At least the file ${file} was not generated at ${DIRMONAN}/testcase/runs/${EXP}/${LABELI}/wpsprd/. \n"
    echo -e  "${RED}==>${NC} Check logs at ${DIRMONAN}/testcase/runs/${EXP}/${LABELI}/logs . Exiting script. \n"
    exit -1
  fi
done



echo -e  "${GREEN}==>${NC} Submiting InitAtmos_exe.sh...\n"
cd ${DIRMONAN}/testcase/runs/${EXP}/${LABELI}
sbatch --wait InitAtmos_exe.sh

if [ ! -e x1.${RES}.init.nc ]; then
  echo -e  "\n${RED}==>${NC} ***** ATTENTION *****\n"	
  echo -e  "${RED}==>${NC} Init Atmosphere phase fails ! Check logs at ${DIRMONAN}/testcase/runs/${EXP}/${LABELI}/logs . Exiting script.\n"
  exit -1
fi


echo -e  "${GREEN}==>${NC} Submitting MONAN and waiting for finish before exit ... \n"
echo -e  "${GREEN}==>${NC} Logs being generated at ${DIRMONAN}/testcase/runs/${EXP}/${LABELI}/logs ... \n"
echo -e  "sbatch ${DIRMONAN}/testcase/runs/${EXP}/${LABELI}/monan_exe.sh"
sbatch --wait ${DIRMONAN}/testcase/runs/${EXP}/${LABELI}/monan_exe.sh
# output files are checked at monan_exe.sh

echo -e "${GREEN}==>${NC} Please, check the output log files at ${DIRMONAN}/testcase/runs/${EXP}/${LABELI}/logs to be sure that MONAN ended successfully. \n"



echo -e  "\n${GREEN}==>${NC} Executing post processing...\n"
cd ${DIRMONAN}/testcase/runs/${EXP}/${LABELI}/postprd
${DIRMONAN}/testcase/runs/${EXP}/${LABELI}/postprd/PostAtmos_exe.sh

files_pos=("mean.nc" "wind+pw_sfc.nc" "surface.nc" "include_fields" "prec.gs" "MONAN.png")
for file in "${files_pos[@]}"; do
  if [[ ! -e "$file" ]]; then
    echo -e  "\n${RED}==>${NC} ***** ATTENTION *****\n"         
    echo -e  "${RED}==>${NC} Post fails ! At least the file ${file} was not generated at ${DIRMONAN}/testcase/runs/${EXP}/${LABELI}/postprd \n"
    echo -e  "${RED}==>${NC} Check ${DIRMONAN}/testcase/runs/${EXP}/${LABELI}/logs/pos.out . Exiting script. \n"
    exit -1
  fi
done


echo -e  "${GREEN}==>${NC} Script ${0} completed. \n"

exit
