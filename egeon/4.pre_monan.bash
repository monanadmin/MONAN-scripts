#!/bin/bash

#if [ $# -ne 1 ]
#then
#   echo ""
#   echo "${0} [root_dir]"
#   echo ""
#   echo "root_dir :: root directory where you want to intall MPAS-set."
#   echo ""
#   exit
#fi

#DIRroot=${1}
export DIRroot=$(pwd)
export DIRMPAS=${DIRroot}/MPAS

export DIRDADOS=/mnt/beegfs/monan/dados/MPAS_v8.0.1 
export WPSDIR=$(spack location -i wps@4.3.1%gcc@9.4.0)




#----------------------------------


mkdir -p ${DIRMPAS}/exec 
mkdir -p ${DIRMPAS}/logs 
mkdir -p ${DIRMPAS}/namelist 
mkdir -p ${DIRMPAS}/src
mkdir -p ${DIRMPAS}/tar
 
echo ""
echo -e  "${GREEN}==>${NC} Copying ungrib.exe from WPS dir...\n"
cp -f ${WPSDIR}/ungrib.exe ${DIRMPAS}/exec


echo ""
echo -e  "${GREEN}==>${NC} Copying and decompressing all data for preprocessing...\n"
cd ${DIRMPAS}/tar
tar -xzf ${DIRDADOS}/MPAS_testcase.v1.0.tgz -C ${DIRroot}
tar -xzf ${DIRDADOS}/MPAS_data_v1.0_ADDED_ERA5_INVARIANT.tgz -C ${DIRMPAS}


# não já está compactado .. TODO remover comentários abaixo
#echo ""
#echo -e  "${GREEN}==>${NC} Decompressing meshes data...\n"
#cd ${DIRMPAS}/data/meshes
#tar -xzf x1.1024002.tar.gz
#tar -xzf x1.2621442.tar.gz


echo ""
echo -e  "${GREEN}==>${NC} Creating make_static.sh for submiting init_atmosphere...\n"
cd ${DIRMPAS}/testcase/scripts
${DIRMPAS}/testcase/scripts/static.sh ERA5 1024002

echo ""
echo -e  "${GREEN}==>${NC} Executing sbatch make_static.sh...\n"
cd ${DIRMPAS}/testcase/runs/ERA5/static
sbatch --wait make_static.sh

#export QPIDreal=$(qsub -W depend=afterok:${QPIDungrib} InitAtmos_exe.sh)
#echo "QPIDread: ${QPIDreal}"

#if [ -s  ${DIRMPAS}/testcase/runs/ERA5/static/x1.1024002.static.nc ]

cd ${DIRMPAS}/testcase/scripts
${DIRMPAS}/testcase/scripts/run_mpas_gnu.egeon ERA5 2021010100
mkdir -p ${HOME}/local/lib64
cp -f /usr/lib64/libjasper.so* ${HOME}/local/lib64
cd ${DIRMPAS}/testcase/runs/ERA5/2021010100/wpsprd/
sbatch --wait degrib_exe.sh
cd ${DIRMPAS}/testcase/runs/ERA5/2021010100
sbatch --wait InitAtmos_exe.sh



exit
