#!/bin/bash

# TODO list:
# - CR: TODO: trazer o script de submissao do modelo para este script


export DIRroot=$(pwd)
export DIRMONAN=${DIRroot}/MONAN
dirFORECAST=${DIRMONAN}/testcase/runs/ERA5/2021010100

export GREEN='\033[1;32m'  # Green
export NC='\033[0m'        # No Color

function modifySimulationTime(){
#x1.1024002.init.nc
#   PARTITION       NAME      USER         ST TIME NODES CPUS NODELIST(REASON) 
# sequana_cpu_dev   MODEL. eduardo.garcia2  R 15:15 4 64 sdumont[6165-6168]
echo " duas alteracoes para reduzir o tempo de processamento"
comando="sed 's/_24:/_04:/' ./MONAN/testcase/runs/ERA5/2021010100/namelist.atmosphere -i"
echo $comando; eval $comando
comando="sed 's/diag.2021-01-02_00/diag.2021-01-01_04/'       ${dirFORECAST}/monan_exe.sh  -i"
echo $comando; eval $comando
comando="sed 's/history.2021-01-02_00/history.2021-01-01_03/' ${dirFORECAST}/postprd/ngrid2latlon.sh -i"
echo $comando; eval $comando
}
modifySimulationTime

echo -e  "${GREEN}==>${NC} Submitting MONAN and waiting for finish before exit ... \n"
echo -e  "${GREEN}==>${NC} Logs being generated at ${dirFORECAST}/logs ... \n"
comando="sbatch        ${dirFORECAST}/monan_exe.sh"
comando="sbatch --wait ${dirFORECAST}/monan_exe.sh"
echo $comando; eval $comando

# output files are checked at monan_exe.sh

echo -e "${GREEN}==>${NC} Please, check the output log files at ${DIRMONAN}/testcase/runs/ERA5/2021010100/logs to be sure that MONAN ended successfully. \n"
echo -e "${GREEN}==>${NC} Script ${0} completed. \n"
