#!/bin/bash

#if [ $# -ne 1 ]
#then
#   echo ""
#   echo "${0} dir_spack_name"
#   echo ""
#   exit
#fi



GREEN='\033[1;32m'       # Green
NC='\033[0m' # No Color

# Installing WPS from spack:------
echo ""
echo -e  "${GREEN}==>${NC} Installing WPS from spack...\n"
spack compiler find
spack external find cmake
spack external find perl
spack external find openmpi

spack spec    wps@4.3.1%gcc@9.4.0
spack install wps@4.3.1%gcc@9.4.0

export WPSDIR=$(spack location -i wps@4.3.1%gcc@9.4.0)
if [ ! -s ${WPSDIR}/ungrib.exe ]
then
   echo "Erro:: ${WPSDIR}/ungrib.exe not installed."
   exit
fi

