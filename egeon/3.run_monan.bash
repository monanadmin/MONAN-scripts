#!/bin/bash

# TODO list:
# - CR: TODO: trazer o script de submissao do modelo para este script


export DIRroot=$(pwd)
export DIRMPAS=${DIRroot}/MPAS

export GREEN='\033[1;32m'  # Green
export NC='\033[0m'        # No Color

echo -e  "${GREEN}==>${NC} Submitting MPAS and waiting for finish before exit ... \n"
echo -e  "${GREEN}==>${NC} Logs being generated at ${DIRMPAS}/testcase/runs/ERA5/2021010100/logs ... \n"
echo -e  "sbatch ${DIRMPAS}/testcase/runs/ERA5/2021010100/mpas_exe.sh"
sbatch --wait ${DIRMPAS}/testcase/runs/ERA5/2021010100/mpas_exe.sh
# output files are checked at mpas_exe.sh

