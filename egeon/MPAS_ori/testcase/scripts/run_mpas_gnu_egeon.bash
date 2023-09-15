#!/bin/bash
#-----------------------------------------------------------------------------#
#                                   DIMNT/INPE                                #
#-----------------------------------------------------------------------------#
#BOP
#
# !SCRIPT: run_mpas
#
# !DESCRIPTION:
#        Script para rodar o MPAS
#        Realiza as seguintes tarefas:
#           o Ungrib os dados do GFS, ERA5
#           o Interpola para grade do modelo
#           o Cria condicao inicial e de fronteria
#           o Integra o modelo MPAS
#           o Pos-processamento (netcdf para grib2, regrid latlon, crop)
#
# !CALLING SEQUENCE:
#     
#        ./run_mpas_gnu.egeon EXP_NAME LABELI
#
# For benchmark:
#        ./run_mpas_gnu.egeon CFSR 2010102300
#
# For ERA5 datasets
#
#        ./run_mpas_gnu.egeon ERA5 2021010100
#
#           o EXP_NAME : Forcing: ERA5, CFSR, GFS, etc.
#           o LABELI   : Initial: date 2015030600
#           o FCST     : Forecast: 24, 36, 72, 84, etc. [hours]
#
# !REVISION HISTORY:
# 30 sep 2022 - JPRF
# 12 oct 2022 - GAM Group - MPAS on EGEON DELL cluster
# 23 oct 2022 - GAM Group - MPAS benchmark on EGEON
#
# !REMARKS:
#
#EOP
#-----------------------------------------------------------------------------!
#EOC

function usage(){
   sed -n '/^# !CALLING SEQUENCE:/,/^# !/{p}' ./run_mpas_gnu.egeon | head -n -1
}

#
# Verificando argumentos de entrada
#

if [ $# -ne 2 ]; then
   usage
   exit 1
fi

export HUGETLB_VERBOSE=0

#
# Caminhos
#
vlabel="v8.0.1"

HSTMAQ=$(hostname)
BASEDIR=$(dirname $(pwd))
RUNDIR=${BASEDIR}/runs
DATADIR=${BASEDIR}/data
EXEDIR=${BASEDIR}/bin
TBLDIR=${BASEDIR}/tables
NMLDIR=${BASEDIR}/namelist
SCRDIR=${BASEDIR}/scripts
GEODATA=${BASEDIR}/data/WPS_GEOG/
TMPDIR=${BASEDIR}/TMP
FIXDIR=${BASEDIR}/fix
GEODIR=${DATADIR}/geog
STCDIR=${DATADIR}/static

# TODO - move exex to EXECPATH (below)
EXECFILEPATH=${BASEDIR}/../src/MPAS-Model_${vlabel}_egeon.gnu940

EXECPATH=${BASEDIR}/../exec

#
# pegando argumentos
#
EXP=${1}
LABELI=${2}; start_date=${LABELI:0:4}-${LABELI:4:2}-${LABELI:6:2}_${LABELI:8:2}:00:00

EXPDIR=${RUNDIR}/${EXP}/${LABELI}
LOGDIR=${EXPDIR}/logs
#DIRLATLON=${EXPDIR}/output

#if [ ! -d ${DIRLATLON} ]; then
# mkdir -p ${DIRLATLON}
#fi

#
# Initial Conditions: 
#
# GFS operacional                    GFS
# GFS analysis                       FNL
# ERA5 reanalysis                    ERA5
#
USERDATA=${EXP}

OPERDIR=${BASEDIR}/data/${USERDATA}

BNDDIR=$OPERDIR/${LABELI:0:10}

echo $BNDDIR

if [ ! -d ${BNDDIR} ]; then
   echo "Condicao de contorno inexistente !"
   echo "Verifique a data da rodada."
   echo "$0 ${LABELI}"
   exit 1                     # close for running only the model
fi

#
# Configuracoes
#

JobElapsedTime=01:00:00 # Tempo de duracao do Job
MPITasks=32             # Numero de processadores que serao utilizados no Job
TasksPerNode=32         # Numero de processadores utilizados por tarefas MPI
ThreadsPerMPITask=1     # Number of cores hosting OpenMP threads

#
# Criando diretorios da rodada
#
# logs
# scripts
# pre-processing
# production 
# post-processing: 
# tables
# parameters
#
if [ ! -e ${EXPDIR} ]; then
   mkdir -p ${EXPDIR}
   mkdir -p ${EXPDIR}/logs
   mkdir -p ${EXPDIR}/scripts
   mkdir -p ${EXPDIR}/mpasprd
   mkdir -p ${EXPDIR}/wpsprd
   mkdir -p ${EXPDIR}/postprd
   cd ${EXPDIR}/postprd
   ln -sf ${EXEDIR}/convert_mpas .
   cp ${SCRDIR}/ngrid2latlon.sh .
   cp ${SCRDIR}/include* .          # choice only some variables
   cp ${SCRDIR}/target* .           # regrid for regions
   cp ${BASEDIR}/GrADs/*.gs .       # example GrADs script 
   cp ${BASEDIR}/NCL/*.ncl .        # example NCL script
fi
#

cd ${EXPDIR}

##############################################################################
#
#                               links
#
##############################################################################

if [ ${EXP} = "ERA5" ]; then

ln -sf ${BASEDIR}/runs/${EXP}/static/*.nc .

cd ${EXPDIR}/wpsprd

#

echo "FORECAST "${LABELI}

ln -sf ${TBLDIR}/Vtable.ERA-interim.pl ./Vtable

cp ${SCRDIR}/link_grib.csh .

ln -sf ${EXECPATH}/ungrib.exe                    .

ln -sf ${BNDDIR}/*.grb .

ln -sf ${OPERDIR}/invariant/*.grb .

export start_date=${LABELI:0:4}-${LABELI:4:2}-${LABELI:6:2}_${LABELI:8:2}:00:00

#
# scripts
#
JobName=era4mpas

cat > degrib_exe.sh << EOF0
#!/bin/bash
#SBATCH --job-name=${JobName}
#SBATCH --nodes=1
#SBATCH --partition=batch
#SBATCH --tasks-per-node=1                      # ic for benchmark
####SBATCH --ntasks=2048
#SBATCH --time=00:30:00
#SBATCH --output=${LOGDIR}/my_job_ungrib.o%j    # File name for standard output
#SBATCH --error=${LOGDIR}/my_job_ungrib.e%j     # File name for standard error output
#
ulimit -s unlimited
ulimit -c unlimited
ulimit -v unlimited

export PMIX_MCA_gds=hash

echo  "STARTING AT \`date\` "
Start=\`date +%s.%N\`
echo \$Start > Timing.degrib
#

. ${DIRroot}/spack_wps/env_wps.sh
export LD_LIBRARY_PATH=\$LD_LIBRARY_PATH:${HOME}/local/lib64

# Load packges for WPS@GNU:
spack load --only dependencies wps@4.3.1%gcc@9.4.0
spack load --list

ldd ungrib.exe

cd $EXPDIR/wpsprd

if [ -e namelist.wps ]; then rm -f namelist.wps; fi
#
# invariant variables [ONLY FOR BENCHMARK]
#
# LSM
#
sed -e "s,#LABELI#,1979-01-01_00:00:00,g;s,#PREFIX#,LSM,g" \
	${NMLDIR}/namelist.wps.TEMPLATE > ./namelist.wps

./link_grib.csh \
	e5.oper.invariant.128_172_lsm.ll025sc.1979010100_1979010100.grb

mpirun -np 1 ./ungrib.exe
mv ungrib.log ungrib.lsm.log

#
# SOILGHT
# 
rm -f namelist.wps

sed -e "s,#LABELI#,1979-01-01_00:00:00,g;s,#PREFIX#,GEO,g" \
	${NMLDIR}/namelist.wps.TEMPLATE > ./namelist.wps

rm -f GRIBFILE.AAA
./link_grib.csh \
	e5.oper.invariant.128_129_z.ll025sc.1979010100_1979010100.grb

mpirun -np 1 ./ungrib.exe
mv ungrib.log ungrib.geo.log

#
# Now surface and upper air atmospheric variables
#
rm GRIBFILE.* namelist.wps

sed -e "s,#LABELI#,${start_date},g;s,#PREFIX#,FILE,g" \
	${NMLDIR}/namelist.wps.TEMPLATE > ./namelist.wps

./link_grib.csh e5.oper.an.*.grb

mpirun -np 1 ./ungrib.exe

echo ${start_date:0:13}

cat FILE\:${start_date:0:13} LSM\:1979-01-01_00 > FILE2:${start_date:0:13}
cat FILE2\:${start_date:0:13} GEO\:1979-01-01_00 > FILE3:${start_date:0:13}

rm -f GRIBFILE.*

End=\`date +%s.%N\`
echo  "FINISHED AT \`date\` "
echo \$End   >>Timing.degrib
echo \$Start \$End | awk '{print \$2 - \$1" sec"}' >> Timing.degrib

grep "Successful completion of program ungrib.exe" ungrib.log >& /dev/null

if [ \$? -ne 0 ]; then
   echo "  BUMMER: Ungrib generation failed for some yet unknown reason."
   echo " "
   tail -10 ${LOGDIR}/ungrib.log
   echo " "
   exit 21
fi
   echo "  ####################################"
   echo "  ### Ungrib completed - \$(date) ####"
   echo "  ####################################"
   echo " " 
#
# clean up and remove links
#
   mv ungrib.*.log ${LOGDIR}
   mv ungrib.log ${LOGDIR}/ungrib.${start_date}.log
   mv Timing.degrib ${LOGDIR}
   mv namelist.wps degrib_exe.sh ${EXPDIR}/scripts
   rm -f link_grib.csh
   cd ..
   ln -sf wpsprd/FILE3\:${start_date:0:13} .
   find ${EXPDIR}/wpsprd -maxdepth 1 -type l -exec rm -f {} \;

echo "End of degrib Job"

exit 0
EOF0

###############################################################

chmod +x degrib_exe.sh

###############################################################################
#
#             Initial conditions (ANALYSIS/ERA5) for MPAS grid
#
###############################################################################

cd ${EXPDIR}

# namelist

sed -e "s,#LABELI#,${start_date},g;s,#GEODAT#,${GEODATA},g" \
	 ${NMLDIR}/namelist.init_atmosphere.TEMPLATE > ./namelist.init_atmosphere

cp ${NMLDIR}/streams.init_atmosphere.TEMPLATE ./streams.init_atmosphere
ln -sf ${NMLDIR}/x1.1024002.graph.info.part.32 .

# executable
ln -sf ${EXECFILEPATH}/init_atmosphere_model init_atmosphere_model

JobName=ic_mpas

cat > InitAtmos_exe.sh <<EOF0
#!/bin/bash
#SBATCH --job-name=${JobName}
#####SBATCH --nodes=1                         # depends on how many boundary files are available
#SBATCH --nodes=2                             # TESTE DENIS - erro de mem com mpich
#SBATCH --partition=batch 
#####SBATCH --tasks-per-node=32               # only for benchmark
#SBATCH --tasks-per-node=16                   # TESTE DENIS - erro de OOM com mpich
#SBATCH --time=${JobElapsedTime}
#SBATCH --output=${LOGDIR}/my_job_ic.o%j    # File name for standard output
#SBATCH --error=${LOGDIR}/my_job_ic.e%j     # File name for standard error output
#
export OMP_NUM_THREADS=1
ulimit -c unlimited
ulimit -v unlimited
ulimit -s unlimited

export PMIX_MCA_gds=hash

${DIRroot}/load_monan_app_modules.sh

# Load packges for MPAS@GNU:
export NETCDF=/mnt/beegfs/monan/libs/netcdf
export PNETCDF=/mnt/beegfs/monan/libs/PnetCDF

cd ${EXPDIR}

echo  "STARTING AT \`date\` "
Start=\`date +%s.%N\`
echo \$Start >  ${EXPDIR}/Timing.InitAtmos

mpirun -n 32 ./init_atmosphere_model

# Wait for all jobs to finish before exiting the job submission script

#wait

End=\`date +%s.%N\`
echo  "FINISHED AT \`date\` "
echo \$End   >> ${EXPDIR}/Timing.InitAtmos
echo \$Start \$End | awk '{print \$2 - \$1" sec"}' >>  ${EXPDIR}/Timing.InitAtmos

 mv Timing.InitAtmos log.*.out ${LOGDIR}
 mv namelist.init* streams.init* ${EXPDIR}/scripts
 mv InitAtmos_exe.sh ${EXPDIR}/scripts


date
exit 0
EOF0

chmod +x InitAtmos_exe.sh

else

echo "Benchmark CFSR 2010102300 15 km"
ln -sf ${BNDDIR}/x1.* .
ln -sf ${NMLDIR}/namelist.atmosphere.BENCH namelist.atmosphere
ln -sf ${NMLDIR}/streams.atmosphere.BENCH streams.atmosphere

fi

###############################################################################
#
#                             Rodando o Modelo
#
###############################################################################

#
# Configuracoes para o modelo (pre-operacao/demo)
#

cd ${EXPDIR}

JobName=MPAS.GNU        # Nome do Job
cores=512

#ln -sf ${EXEDIR}/atmosphere_model .
ln -sf ${EXECFILEPATH}/atmosphere_model .
ln -sf ${TBLDIR}/* .

if [ ${EXP} = "ERA5" ]; then
sed -e "s,#LABELI#,${start_date},g" \
         ${NMLDIR}/namelist.atmosphere.TEMPLATE > ./namelist.atmosphere
cp ${NMLDIR}/streams.atmosphere.TEMPLATE streams.atmosphere
fi

cp ${NMLDIR}/stream_list.atmosphere.* .

if [ ${EXP} = "ERA5" ]; then
 ln -sf ${NMLDIR}/x1.1024002.graph.info.part.${cores} .
else
 ln -sf ${NMLDIR}/x1.2621442.graph.info.part.${cores} .
fi 

cat > mpas_exe.sh <<EOF0
#!/bin/bash
#SBATCH --nodes=8
#SBATCH --ntasks=${cores}
#SBATCH --tasks-per-node=64
#SBATCH --partition=batch
#SBATCH --job-name=${JobName}
#SBATCH --time=2:00:00         
#SBATCH --output=${LOGDIR}/my_job_mpas.o%j   # File name for standard output
#SBATCH --error=${LOGDIR}/my_job_mpas.e%j    # File name for standard error output

export executable=atmosphere_model
export PMIX_MCA_gds=hash

${DIRroot}/load_monan_app_modules.sh

# Load packges for MPAS@GNU:
export NETCDF=/mnt/beegfs/monan/libs/netcdf
export PNETCDF=/mnt/beegfs/monan/libs/PnetCDF

export OMPI_MCA_btl_openib_allow_ib=1
export OMPI_MCA_btl_openib_if_include="mlx5_0:1"
export PMIX_MCA_gds=hash
ulimit -s unlimited
MPI_PARAMS="-iface ib0 -bind-to core -map-by core"
export OMP_NUM_THREADS=1
export MKL_NUM_THREADS=1
export I_MPI_DEBUG=5
export MKL_DEBUG_CPU_TYPE=5
export I_MPI_ADJUST_BCAST=12 ## NUMA aware SHM-Based (AVX512)

cd ${EXPDIR}


echo \$SLURM_JOB_NUM_NODES

echo  "STARTING AT \`date\` "
Start=\`date +%s.%N\`
echo \$Start >  ${EXPDIR}/Timing

time mpirun -env UCX_NET_DEVICES=mlx5_0:1 -genvall -np \$SLURM_NTASKS ./${executable}

End=\`date +%s.%N\`
echo  "FINISHED AT \`date\` "
echo \$End   >> ${EXPDIR}/Timing
echo \$Start \$End | awk '{print \$2 - \$1" sec"}' >>  ${EXPDIR}/Timing

#
# move dataout, clean up and remove files/links
#
mv log.atmosphere.*.out ${LOGDIR}

mv namelist.atmosphere ${EXPDIR}/scripts
mv mpas_exe.sh ${EXPDIR}/scripts
mv stream* ${EXPDIR}/scripts
mv x1.*.init.nc* ${EXPDIR}/mpasprd
mv diag* ${EXPDIR}/mpasprd
mv histor* ${EXPDIR}/mpasprd
mv Timing ${LOGDIR}/Timing.MPAS

find ${EXPDIR} -maxdepth 1 -type l -exec rm -f {} \;

exit 0
EOF0

chmod +x mpas_exe.sh

exit 0

#######################################################################
#
#                         Post-processing
#
#######################################################################

cd ${EXPDIR}/postprd

#

exit 0

