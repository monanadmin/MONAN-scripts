#!/bin/bash

# TODO list:
# - CR: inserir cabecalhos padronizados nos scripts
# - CR: retirar execessos de exports, eg: NETCDFDIR=, NETCDF= (do load_monan_app_modules.sh)
# - CR: todos os modules loads devem constar no load_monan_app_modules.sh
# - CR: definicoes de colors deveriam constar no load_monan_app_modules.sh tbm:
# - EGK: NETCDFDIR e PNETCDFDIR obtidos de load_monan_app_modules.sh

#CR: TODO: definicoes de colors deveriam constar no load_monan_app_modules.sh tbm:
GREEN='\033[1;32m'  # Green
  RED='\033[1;31m'    # Red
   NC='\033[0m'        # No Color

function echoGreen(){ echo -en  "${GREEN}==>${1}${NC}\n"; }
function echoRed  (){ echo -en  "${RED}==>${1}${NC}\n"; }

if [ $# -ne 1 ]
then
   echo ""
   echoRed "Instructions: execute the command below"
   echo ""
   echoRed "${0} [G]"
   echo ""
   echoRed "G :: GitHub link for your personal fork, eg: https://github.com/MYUSER/MONAN-Model.git"
   exit
fi

version="8"
github_link=${1}


case ${version} in
   8) vlabel="v0.1.0";;
   7) vlabel="v7.3";;
   6) vlabel="v6.31";;
esac

machine=sdumont
compiler=gnu


export          DIRroot=$(pwd)
export    MONAN_SRC_DIR=${DIRroot}/MONAN_src
export         MONANDIR=${MONAN_SRC_DIR}/MONAN-Model_${vlabel}_${machine}.${compiler}
export CONVERT_MPAS_DIR=${MONAN_SRC_DIR}/convert_mpas
export   MONAN_EXEC_DIR=${DIRroot}/MONAN/exec
mkdir -p ${MONAN_EXEC_DIR}
mkdir -p ${MONAN_SRC_DIR}
mkdir -p ${CONVERT_MPAS_DIR}

# install init_atmosphere_model and atmosphere_model

echo ""
echoGreen "Moduling environment for MONAN model...\n"

function createExecs(){ # atmosphere_model init_atmosphere_model ungrib.exe

cd ${DIRroot}

export NETCDFDIR=${NETCDF}
export PNETCDFDIR=${PNETCDF}

if [ -d "${MONANDIR}" ]; then
    echo ""
    echoGreen "Source dir already exists, updating it ...\n"
else
    echo ""
    echoGreen "Cloning your fork repository...\n"
    git clone ${github_link} ${MONANDIR}
    if [ ! -d "${MONANDIR}" ]; then
        echo ""
        echoRed "An error occurred while cloning your fork. Possible causes: wrong URL, user or password.\n"
        exit -1
    fi
fi

cd ${MONANDIR}

branch_name="develop"
if git checkout "$branch_name" 2>/dev/null; then
    git pull
    echo ""
    echo -e "${GREEN}==>${NC} Successfully checked out and updated branch: $branch_name"
else
    echo ""
    echo -e "${RED}==>${NC} Failed to check out branch: $branch_name"
    echo -e "${RED}==>${NC} Please check if you have this branch. Exiting ..."
    exit -1
fi

echo ""
echo -e  "${GREEN}==>${NC} Making compile script...\n"
cat << EOF > make.sh
#!/bin/bash
#Usage: make target CORE=[core] [options]
#Example targets:
#    ifort
#    gfortran
#    xlf
#    pgi
#Availabe Cores:
#    atmosphere
#    init_atmosphere
#    landice
#    ocean
#    seaice
#    sw
#    test
#Available Options:
#    DEBUG=true    - builds debug version. Default is optimized version.
#    USE_PAPI=true - builds version using PAPI for timers. Default is off.
#    TAU=true      - builds version using TAU hooks for profiling. Default is off.
#    AUTOCLEAN=true    - forces a clean of infrastructure prior to build new core.
#    GEN_F90=true  - Generates intermediate .f90 files through CPP, and builds with them.
#    TIMER_LIB=opt - Selects the timer library interface to be used for profiling the model. Options are:
#                    TIMER_LIB=native - Uses native built-in timers in MPAS
#                    TIMER_LIB=gptl - Uses gptl for the timer interface instead of the native interface
#                    TIMER_LIB=tau - Uses TAU for the timer interface instead of the native interface
#    OPENMP=true   - builds and links with OpenMP flags. Default is to not use OpenMP.
#    OPENACC=true  - builds and links with OpenACC flags. Default is to not use OpenACC.
#    USE_PIO2=true - links with the PIO 2 library. Default is to use the PIO 1.x library.
#    PRECISION=single - builds with default single-precision real kind. Default is to use double-precision.
#    SHAREDLIB=true - generate position-independent code suitable for use in a shared library. Default is false.


export NETCDF=${NETCDFDIR}
export PNETCDF=${PNETCDFDIR}
# PIO is not necessary for version 8.* If PIO is empty, MPAS Will use SMIOL
export PIO=

make clean CORE=atmosphere
make -j 8 gfortran CORE=atmosphere OPENMP=true USE_PIO2=false PRECISION=single 2>&1 | tee make.output

mkdir -p ${MONANDIR}/bin
mv ${MONANDIR}/atmosphere_model ${MONANDIR}/bin/
mv ${MONANDIR}/build_tables ${MONANDIR}/bin/
make clean CORE=atmosphere

make clean CORE=init_atmosphere
make -j 8 gfortran CORE=init_atmosphere OPENMP=true USE_PIO2=false PRECISION=single 2>&1 | tee make.output

mv ${MONANDIR}/init_atmosphere_model ${MONANDIR}/bin/
make clean CORE=init_atmosphere
cp -f ${MONANDIR}/bin/init_atmosphere_model ${MONAN_EXEC_DIR}/
cp -f ${MONANDIR}/bin/atmosphere_model ${MONAN_EXEC_DIR}/
cp -f ${MONANDIR}/bin/build_tables ${MONAN_EXEC_DIR}/

if [ -s "${MONAN_EXEC_DIR}/init_atmosphere_model" ] && [ -e "${MONAN_EXEC_DIR}/atmosphere_model" ]; then
    echo ""
    echo -e "${GREEN}==>${NC} Files init_atmosphere_model and atmosphere_model generated Successfully in ${MONANDIR}/bin and copied to ${MONAN_EXEC_DIR} !"
    echo
else
    echo -e "${RED}==>${NC} !!! An error occurred during build. Check output"
    exit -1
fi

EOF
chmod a+x make.sh

echo ""
echo -e  "${GREEN}==>${NC} Installing init_atmosphere_model and atmosphere_model...\n"
echo ""

cd ${MONANDIR}
#para funcionamento no Sdumont com compilador gnu - BD_fev_2024
sed '/DMPAS_BUILD_TARGET/a override LIBS += -lstdc++' Makefile  -i
. ${MONANDIR}/make.sh


cd ${DIRroot}

}  # createExecs()


function createConvert_mpas(){

  echo -e  "${GREEN}==>${NC} Moduling environment for convert_mpas...\n"
  echo ""
  echo -e  "${GREEN}==>${NC} Cloning convert_mpas repository...\n"
#  git clone http://github.com/mgduda/convert_mpas.git
#  wget https://github.com/monanadmin/convert_mpas/archive/refs/tags/1.0.0.tar.gz
#  tar -xvf 1.0.0.tar.gz

export convert_mpasDIR="$(ls | grep "^convert_mpas-1.0.0" |grep -v zip)"
  echo convert_mpasDIR=$convert_mpasDIR +++
export CONVERT_MPAS_DIR=${DIRroot}/00convert_mpas
export CONVERT_MPAS_DIR=${DIRroot}/$convert_mpasDIR

  echo CONVERT_MPAS_DIR=$CONVERT_MPAS_DIR +++; 
  cd ${CONVERT_MPAS_DIR}
  pwd
  echo ""
  echo -e  "${GREEN}==>${NC} Installing convert_mpas...\n"
  make clean
  comando="make  2>&1 | tee make.convert.output"
  echo $comando; eval $comando;

  cp -f ${CONVERT_MPAS_DIR}/convert_mpas ${MONAN_EXEC_DIR}/

  cd ${DIRroot}

  if [ -s "${MONAN_EXEC_DIR}/convert_mpas" ] ; then
    echo ""
    echo -e "${GREEN}==>${NC} File convert_mpas generated Sucessfully in ${CONVERT_MPAS_DIR} and copied to ${MONAN_EXEC_DIR} !"
    echo
  else
    echo -e "${RED}==>${NC} !!! An error occurred during convert_mpas build. Check output"
    exit -1
  fi

  echo -e  "${GREEN}==>${NC} Script ${0} completed. \n"
} # function createConvert_mpas(){

source ${DIRroot}/load_monan_app_modules.sh $compiler
createExecs # atmosphere_model init_atmosphere_model ungrib.exe
createConvert_mpas
ls -ltr  $MONAN_EXEC_DIR

