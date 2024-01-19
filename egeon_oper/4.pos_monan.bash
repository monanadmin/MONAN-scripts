#!/bin/bash

# TODO list:
# - ...


export DIRroot=$(pwd)
export DIRMONAN=${DIRroot}/MONAN
POST_DIR=${DIRMONAN}/testcase/runs/GFS/2021060100/postprd
LOG_FILE=${POST_DIR}/logs/pos.out

export GREEN='\033[1;32m'  # Green
export RED='\033[1;31m' # Red
export NC='\033[0m'        # No Color

# start post processing

echo -e  "\n${GREEN}==>${NC} Executing post processing...\n"
cd ${POST_DIR}
${POST_DIR}/PostAtmos_exe.sh

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

exit
