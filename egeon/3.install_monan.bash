#!/bin/bash

if [ $# -ne 1 ]
then
   echo ""
   echo "${0} [V]"
   echo ""
   echo "V   :: Mpas version:"
   echo "                      to install v8.0.1 :: 8"
   echo "                      to install v7.3   :: 7"
   echo "                      to install v6.3   :: 6"
   echo ""
   exit
fi

version=${1}
NETCDFDIR=/mnt/beegfs/monan/libs/netcdf
PNETCDFDIR=/mnt/beegfs/monan/libs/PnetCDF
# PIO isn't mandatory anymore in version v8, since included SMIOL lib substitute it
PIODIR=

GREEN='\033[1;32m'  # Green
NC='\033[0m'        # No Color



case ${version} in
   8) vlabel="v8.0.1";;
   7) vlabel="v7.3";;
   6) vlabel="v6.31";;
esac
MPASDIR=$(pwd)/MPAS/src/MPAS-Model_${vlabel}_egeon.gnu940


echo ""
echo -e  "${GREEN}==>${NC} Moduling environment..."

./load_monan_app_modules.sh

echo ""
echo -e  "${GREEN}==>${NC} Cloning repository..."
rm -fr ${MPASDIR}
git clone  https://github.com/MPAS-Dev/MPAS-Model.git ${MPASDIR}
cd ${MPASDIR}
git checkout tags/${vlabel} -b branch_${vlabel}

echo ""
echo -e  "${GREEN}==>${NC} Making compile script..."
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
module purge
module load ohpc
module unload openmpi4
module load mpich-4.0.2-gcc-9.4.0-gpof2pv
module list

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
cp -f ${MPASDIR}/bin/init_atmosphere_model ${MPASDIR}/
cp -f ${MPASDIR}/bin/atmosphere_model ${MPASDIR}/
cp -f ${MPASDIR}/bin/build_tables ${MPASDIR}/

EOF
chmod a+x make.sh


echo ""
echo -e  "${GREEN}==>${NC} execute: the following to compile MPAS:"
echo -e  "${GREEN}==>${NC} cd ${MPASDIR} && source make.sh && cd ../../.."
echo ""

