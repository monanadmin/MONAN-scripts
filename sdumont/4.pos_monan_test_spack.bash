#!/bin/bash

# TODO list:
# - ...


export DIRroot=$(pwd)
export DIRMONAN=${DIRroot}/MONAN
export DIRMONAN_ORI=${DIRroot}/MONAN_ori
export MONAN_EXEC_DIR=${DIRroot}/MONAN/exec
POST_DIR=${DIRMONAN}/testcase/runs/ERA5/2021010100/postprd
LOG_FILE=${POST_DIR}/logs/pos.out

export GREEN='\033[1;32m'  # Green
export RED='\033[1;31m' # Red
export NC='\033[0m'        # No Color

#. ./load_monan_app_modules.sh
module load sequana/current
module load git/2.23_sequana
module load python/3.9.1_sequana
module load cmake/3.23.2_sequana
module load openmpi/gnu/4.1.6_sequana
. /scratch/cenapadrjsd/rpsouto/sequana/spack/v0.18.1/share/spack/setup-env.sh
export SPACK_USER_CONFIG_PATH=/scratch/cenapadrjsd/rpsouto/sequana/.spack/v0.18.1
spack env activate monan
spack load cdo
spack load netcdf-fortran@4.5.4%gcc@13.2.0
#module load cdo/2.4.0_openmpi-4.1.6_sequana
#module load netcdf; module load netcdf-fortran; module load cdo-2.0.4-gcc-9.4.0-bjulvnd; module load opengrads-2.2.1;

# start post processing

echo -e  "\n${GREEN}==>${NC} Executing post processing...\n"
mkdir -p ${POST_DIR}/logs
rm -f ${LOG_FILE}

# copy convert_mpas from MONAN/exec to testcase
cd ${POST_DIR}
rm -f ${POST_DIR}/convert_mpas >> ${LOG_FILE}
#ln -s ${MONAN_EXEC_DIR}/convert_mpas ${POST_DIR} >> ${LOG_FILE}
#ln -s /scratch/cenapadrjsd/rpsouto/sequana/projetos/monan/github/monanadmin/convert_mpas/convert_mpas >> ${LOG_FILE}
ln -s /scratch/cenapadrjsd/rpsouto/sequana/projetos/monan/github/monanadmin/MONAN-scripts/sdumont/convert_mpas/convert_mpas >> ${LOG_FILE}

# copy from repository to testcase and runs /ngrid2latlon.sh
cp ${DIRMONAN_ORI}/testcase/scripts/ngrid2latlon.sh ${POST_DIR}/ngrid2latlon.sh >> ${LOG_FILE}
comando="${POST_DIR}/ngrid2latlon.sh >> ${LOG_FILE} 2>&1"
echo $comando; eval $comando;
errCode=$?; if [ $errCode -ne 0 ]; then echo .. aborted at ./4.pos_monan.bash !! error: $errCode; tail ${LOG_FILE};  exit $errCode; fi
echo ..... $errCode ....
comando="pwd; head ${LOG_FILE} "
echo $comando; eval $comando;
comando="pwd; tail ${LOG_FILE} "
echo $comando; eval $comando;

# copy from repository to testcase and runs prec.gs
cp ${DIRMONAN_ORI}/testcase/scripts/prec.gs ${POST_DIR}/prec.gs >> ${LOG_FILE}
#grads -bpcx "run '${POST_DIR}'/prec.gs" >> ${LOG_FILE} 2>&1
grads -blcx "run ${POST_DIR}/prec.gs" >> ${LOG_FILE} 2>&1

cdo hourmean surface.nc mean.nc >> ${LOG_FILE} 2>&1

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

#exit
spack unload
spack env deactivate
exit
