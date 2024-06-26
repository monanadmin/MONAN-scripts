#!/bin/bash

# TODO list:
# - ...

export DIRroot=$(pwd)
export DIRMONAN=${DIRroot}/MONAN
export DIRMONAN_ORI=${DIRroot}/MONAN_ori
export MONAN_EXEC_DIR=${DIRroot}/MONAN/exec
POST_DIR=${DIRMONAN}/testcase/runs/ERA5/2021010100/postprd
LOG_FILE=/dev/stdout
LOG_FILE=${POST_DIR}/logs/pos.out

export GREEN='\033[1;32m'  # Green
export RED='\033[1;31m' # Red
export NC='\033[0m'        # No Color

source ./load_monan_app_modules.sh $COMPILER

#module load netcdf; module load netcdf-fortran; module load cdo-2.0.4-gcc-9.4.0-bjulvnd; module load opengrads-2.2.1;

# start post processing

echo -e  "\n${GREEN}==>${NC} Executing post processing...\n"
mkdir -p ${POST_DIR}/logs
#rm -f ${LOG_FILE}
date >${LOG_FILE}

# copy convert_mpas from MONAN/exec to testcase
cd ${POST_DIR}
comando="rm -f ${POST_DIR}/convert_mpas >> ${LOG_FILE}"
echo $comando; eval $comando;
comando="ln -s ${MONAN_EXEC_DIR}/convert_mpas ${POST_DIR} >> ${LOG_FILE}"
echo $comando; eval $comando;

# copy from repository to testcase and runs /ngrid2latlon.sh

echo -e "\n  \n   \n"
comando="cp ${DIRMONAN_ORI}/testcase/scripts/ngrid2latlon.sh ${POST_DIR}/ngrid2latlon.sh >> ${LOG_FILE}"
echo $comando; eval $comando;
comando="sed 's/history.2021-01-02_00/history.2021-01-01_03/' ${POST_DIR}/ngrid2latlon.sh -i >> ${LOG_FILE}"
echo $comando; eval $comando
pwd
comando="${POST_DIR}/ngrid2latlon.sh >> ${LOG_FILE} 2>&1"
echo $comando; eval $comando; errCode=$?;
date >>${LOG_FILE}

echo -e "\n  ................. \n"
 if [ $errCode -ne 0 ]; then
   echo .. aborted at ./4.pos_monan.bash !! error: $errCode;
   echo -e "\n  ................. \n"
   comando="head -n8 ${LOG_FILE}"; echo $comando; eval $comando;
   echo -e "\n  ................. \n"
   comando="tail -n5 ${LOG_FILE}"; echo $comando; eval $comando;
   echo -e "\n  ................. \n"
   exit $errCode; 
   echo ..... $errCode ....
   echo -e "\n  ................. \n"
 else 
   comando="tail -n45 ${LOG_FILE}"
   echo $comando; eval $comando;
 fi


exit

# copy from repository to testcase and runs prec.gs
cp ${DIRMONAN_ORI}/testcase/scripts/prec.gs ${POST_DIR}/prec.gs >> ${LOG_FILE}
comando="grads -bpcx "run '${POST_DIR}'/prec.gs" >> ${LOG_FILE} 2>&1"
echo $comando; eval $comando;

pwd
comando="cdo hourmean surface.nc mean.nc >> ${LOG_FILE} 2>&1"
#echo $comando; eval $comando;

files_pos=("mean.nc" "wind+pw_sfc.nc" "surface.nc" "include_fields" "prec.gs" "MONAN.png")
for file in "${files_pos[@]}"; do
  if [[ ! -e "$file" ]]; then
    echo -e  "\n${RED}==>${NC} ***** ATTENTION *****\n"         
    echo -e  "${RED}==>${NC} Post fails ! At least the file ${file} was not generated at ${POST_DIR} \n"
    echo -e  "${RED}==>${NC} Check ${LOG_FILE} . Exiting script. \n"
    exit -1
  fi
done

echo -e  "${GREEN}==>${NC}  Script ${0} completed. \n"
echo -e  "${GREEN}==>${NC}  Log file: ${LOG_FILE} . End of script. \n"

