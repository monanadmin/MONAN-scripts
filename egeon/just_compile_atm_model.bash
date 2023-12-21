#!/bin/bash 

# TODO list:
#

vlabel="v0.1.0"
export DIRroot=$(pwd)
export MONAN_SRC_DIR=${DIRroot}/MONAN_src
export MONANDIR=${MONAN_SRC_DIR}/MONAN-Model_${vlabel}_egeon.gnu940
export CONVERT_MPAS_DIR=${MONAN_SRC_DIR}/convert_mpas
export MONAN_EXEC_DIR=${DIRroot}/MONAN/exec
export EXPDIR=${DIRroot}/MONAN/testcase/runs/ERA5/2021010100
mkdir -p ${MONAN_EXEC_DIR}
mkdir -p ${MONAN_SRC_DIR}
mkdir -p ${CONVERT_MPAS_DIR}

. ${DIRroot}/load_monan_app_modules.sh

export NETCDFDIR=${NETCDF}
export PNETCDFDIR=${PNETCDF}

cd ${MONANDIR}


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
cp -f ${MONANDIR}/atmosphere_model ${MONANDIR}/bin/
cp -f ${MONANDIR}/build_tables ${MONANDIR}/bin/
cp -f ${MONANDIR}/bin/atmosphere_model ${MONAN_EXEC_DIR}/
cp -f ${MONANDIR}/bin/build_tables ${MONAN_EXEC_DIR}/

if [ -s "${MONAN_EXEC_DIR}/atmosphere_model" ]; then
    echo ""
    echo -e "${GREEN}==>${NC} Executable atmosphere_model generated Successfully in ${MONANDIR}/bin and copied to ${MONAN_EXEC_DIR} !"
    echo
else
    echo -e "${RED}==>${NC} !!! An error occurred during build. Check output"
    exit -1
fi

EOF
chmod a+x make.sh

cd ${MONANDIR}
rm -f stream_list.atmosphere.diagnostics stream_list.atmosphere.output stream_list.atmosphere.surface

. ${MONANDIR}/make.sh

cd ${MONANDIR}
cp -f stream_list.atmosphere.* ${EXPDIR}