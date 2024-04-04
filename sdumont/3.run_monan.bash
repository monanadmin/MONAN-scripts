#!/bin/bash

# TODO list:
# - CR: TODO: trazer o script de submissao do modelo para este script


export DIRroot=$(pwd)
export DIRMONAN=${DIRroot}/MONAN
dirFORECAST=${DIRMONAN}/testcase/runs/ERA5/2021010100

export GREEN='\033[1;32m'  # Green
export NC='\033[0m'        # No Color


echo -e  "${GREEN}==>${NC} Submitting MONAN and waiting for finish before exit ... \n"
echo -e  "${GREEN}==>${NC} Logs being generated at ${dirFORECAST}/logs ... \n"
comando="sbatch        ${dirFORECAST}/monan_exe.sh"
comando="sbatch --wait ${dirFORECAST}/monan_exe.sh"
echo $comando; eval $comando

# output files are checked at monan_exe.sh

echo -e "${GREEN}==>${NC} Please, check the output log files at ${DIRMONAN}/testcase/runs/ERA5/2021010100/logs to be sure that MONAN ended successfully. \n"
echo -e "${GREEN}==>${NC} Script ${0} completed. \n"
