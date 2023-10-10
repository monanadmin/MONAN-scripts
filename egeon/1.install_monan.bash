#!/bin/bash
#CR: TODO: inserir cabecalhos padronizados nos scripts
#CR: TODO: retirar execessos de exports, eg: NETCDFDIR=, NETCDF= (do load_monan_app_modules.sh)
#EGK: NETCDFDIR e PNETCDFDIR obtidos de load_monan_app_modules.sh

if [ $# -ne 1 ]
then
   echo ""
   echo "Instructions: execute the command below"
   echo ""
   echo "${0} [G]"
   echo ""
   echo "G   :: GitHub link for your personal fork, eg: https://github.com/MYUSER/MONAN-Model.git"
   exit
fi

version="8"
github_link=${1}

GREEN='\033[1;32m'  # Green
NC='\033[0m'        # No Color

case ${version} in
   8) vlabel="v8.0.1";;
   7) vlabel="v7.3";;
   6) vlabel="v6.31";;
esac

export DIRroot=$(pwd)
export MPAS_SRC_DIR=${DIRroot}/MPAS_src
export MPASDIR=${MPAS_SRC_DIR}/MPAS-Model_${vlabel}_egeon.gnu940
export CONVERT_MPAS_DIR=${MPAS_SRC_DIR}/convert_mpas
export MPAS_EXEC_DIR=${DIRroot}/MPAS/exec
mkdir -p ${MPAS_EXEC_DIR}
mkdir -p ${MPAS_SRC_DIR}
mkdir -p ${CONVERT_MPAS_DIR}

# install init_atmosphere_model and atmosphere_model

echo ""
echo -e "${GREEN}==>${NC} Moduling environment for MPAS model...\n"


cd ${DIRroot}
. ${DIRroot}/load_monan_app_modules.sh

export NETCDFDIR=${NETCDF}
export PNETCDFDIR=${PNETCDF}

if [ -d "${MPASDIR}" ]; then
    echo -e  "${GREEN}==>${NC} Source dir already exists, updating it ...\n"
else
    echo -e  "${GREEN}==>${NC} Cloning your fork repository...\n"
    git clone ${github_link} ${MPASDIR}
    if [ ! -d "${MPASDIR}" ]; then
        echo "An error occurred while cloning your fork. Possible causes:  wrong URL, user or password.\n"
        exit -1
    fi
fi

cd ${MPASDIR}

branch_name="develop"
if git checkout "$branch_name" 2>/dev/null; then
    git pull
    echo "Successfully checked out and updated branch: $branch_name"
else
    echo "Failed to check out branch: $branch_name"
    echo "Please check if you have this branch. Exiting ..."
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

# TODO: call ./load_monan_app_modules.sh instead
#module purge
#module load ohpc
#module unload openmpi4
#module load mpich-4.0.2-gcc-9.4.0-gpof2pv
#module list



export NETCDF=${NETCDFDIR}
export PNETCDF=${PNETCDFDIR}
# PIO is not necessary for version 8.* If PIO is empty, MPAS will use SMIOL
export PIO=

make clean CORE=atmosphere
make -j 8 gfortran CORE=atmosphere OPENMP=true USE_PIO2=false PRECISION=single 2>&1 | tee make.output

mkdir ${MPASDIR}/bin
mv ${MPASDIR}/atmosphere_model ${MPASDIR}/bin/
mv ${MPASDIR}/build_tables ${MPASDIR}/bin/
make clean CORE=atmosphere

make clean CORE=init_atmosphere
make -j 8 gfortran CORE=init_atmosphere OPENMP=true USE_PIO2=false PRECISION=single 2>&1 | tee make.output

mv ${MPASDIR}/init_atmosphere_model ${MPASDIR}/bin/
make clean CORE=init_atmosphere
cp -f ${MPASDIR}/bin/init_atmosphere_model ${MPAS_EXEC_DIR}/
cp -f ${MPASDIR}/bin/atmosphere_model ${MPAS_EXEC_DIR}/
cp -f ${MPASDIR}/bin/build_tables ${MPAS_EXEC_DIR}/

if [ -s "${MPAS_EXEC_DIR}/init_atmosphere_model" ] && [ -e "${MPAS_EXEC_DIR}/atmosphere_model" ]; then
    echo ""
    echo "Files init_atmosphere_model and atmosphere_model generated Sucessfully in ${MPASDIR}/bin and copied to ${MPAS_EXEC_DIR} !"
    echo
else
    echo "!!! An error occurred during build. Check output"
    exit -1
fi

EOF
chmod a+x make.sh

echo ""
echo -e  "${GREEN}==>${NC} Installing init_atmosphere_model and atmosphere_model...\n"
echo ""

cd ${MPASDIR}
. ${MPASDIR}/make.sh
cd ${DIRroot}


# install convert_mpas

echo ""
echo -e  "${GREEN}==>${NC} Moduling environment for convert_mpas...\n"
#CR: TODO: todos os modules loads devem constar no load_monan_app_modules.sh 
module purge
module load gnu9/9.4.0
module load ohpc
module load phdf5
module load netcdf
module load netcdf-fortran
module list

echo ""
echo -e  "${GREEN}==>${NC} Cloning convert_mpas repository...\n"
cd ${MPAS_SRC_DIR}
git clone http://github.com/mgduda/convert_mpas.git
cd ${CONVERT_MPAS_DIR}
echo ""
echo -e  "${GREEN}==>${NC} Installing convert_mpas...\n"
make clean
make  2>&1 | tee make.convert.output

cp -f ${CONVERT_MPAS_DIR}/convert_mpas ${MPAS_EXEC_DIR}/

cd ${DIRroot}

if [ -s "${MPAS_EXEC_DIR}/convert_mpas" ] ; then
    echo ""
    echo "File convert_mpas generated Sucessfully in ${CONVERT_MPAS_DIR} and copied to ${MPAS_EXEC_DIR} !"
    echo
else
    echo "!!! An error occurred during convert_mpas build. Check output"
    exit -1
fi

