#!/bin/bash

# TODO list:
# - CR: TODO: trazer o script de submissao do modelo para este script


export DIRroot=$(pwd)
export DIRMONAN=${DIRroot}/MONAN

export GREEN='\033[1;32m'  # Green
export NC='\033[0m'        # No Color

echo -e  "${GREEN}==>${NC} Submitting MONAN and waiting for finish before exit ... \n"
echo -e  "${GREEN}==>${NC} Logs being generated at ${DIRMONAN}/testcase/runs/ERA5/2021010100/logs ... \n"
echo -e  "sbatch ${DIRMONAN}/testcase/runs/GFS/2021060100/monan_exe.sh"
sbatch --wait ${DIRMONAN}/testcase/runs/GFS/2021060100/monan_exe.sh
# output files are checked at monan_exe.sh

echo -e "${GREEN}==>${NC} Please, check the output log files at ${DIRMONAN}/testcase/runs/GFS/2021060100/logs to be sure that MONAN ended successfully. \n"
echo -e "${GREEN}==>${NC} Script ${0} completed. \n"
