#!/bin/bash
#echo "-----------------------------         $0  ------------------------------; exit
#-----------------------------------------------------------------------------#
#                                   DIMNT/INPE                                #
#-----------------------------------------------------------------------------#
#BOP
#
# !SCRIPT: run_monan
#
# !DESCRIPTION:
#        Script para rodar o MONAN
#        Realiza as seguintes tarefas:
#           o Ungrib os dados do GFS, ERA5
#           o Interpola para grade do modelo
#           o Cria condicao inicial e de fronteria
#           o Integra o modelo MONAN
#           o Pos-processamento (netcdf para grib2, regrid latlon, crop)
#
# !CALLING SEQUENCE:
#     
#        ./run_monan_gnu.egeon EXP_NAME LABELI
#
# For benchmark:
#        ./run_monan_gnu.bash CFSR 2010102300
#
# For ERA5 datasets
#
#        ./run_monan_gnu.bash ERA5 2021010100
#
#           o EXP_NAME : Forcing: ERA5, CFSR, GFS, etc.
#           o LABELI   : Initial: date 2015030600
#           o FCST     : Forecast: 24, 36, 72, 84, etc. [hours]
#
# !REVISION HISTORY:
# 30 sep 2022 - JPRF
# 12 oct 2022 - GAM Group - MONAN on EGEON DELL cluster
# 23 oct 2022 - GAM Group - MONAN benchmark on EGEON
#
# !REMARKS:
#
#EOP
#-----------------------------------------------------------------------------!
#EOC

function usage(){
   sed -n '/^# !CALLING SEQUENCE:/,/^# !/{p}' ./run_monan_gnu.bash | head -n -1
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

HOME=$SCRATCH 
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

JobElapsedTime=${sTime}  # Tempo de duracao do Job 
MPITasks=${numNucleos}   # Numero de processadores que serao utilizados no Job
TasksPerNode=${MPITasks} # Numero de processadores utilizados por tarefas MPI
ThreadsPerMPITask=1      # Number of cores hosting OpenMP threads

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
   mkdir -p ${EXPDIR}/monanprd
   mkdir -p ${EXPDIR}/wpsprd
   mkdir -p ${EXPDIR}/postprd
   cd ${EXPDIR}/postprd
   cp ${SCRDIR}/ngrid2latlon.sh .
   cp ${SCRDIR}/include* .          # choice only some variables
   cp ${SCRDIR}/target* .           # regrid for regions
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

cp -f ${BASEDIR}/runs/${EXP}/static/*.nc .

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
JobName=era4monan
#
pwd 
cat > degrib_exe.sh << EOF0
#!/bin/bash
#SBATCH --job-name=${JobName}
#SBATCH --nodes=1
# BATCH --tasks=${numNucleos}                     # ic for benchmark
#SBATCH --partition=${INIT_ATM_PART}      # fron load_monan_app_modules.sh
#SBATCH --tasks-per-node=1                      # ic for benchmark
#SBATCH --time=${sTime}
#SBATCH --output=${LOGDIR}/ungrib.o%j    # File name for standard output
#SBATCH --error=${LOGDIR}/ungrib.e%j     # File name for standard error output
#
echo     SLURM_JOB_PARTITION=\$SLURM_JOB_PARTITION
echo      SLURM_JOB_NODELIST=\$SLURM_JOB_NODELIST
echo     SLURM_JOB_NUM_NODES=\$SLURM_JOB_NUM_NODES
echo            SLURM_NTASKS=\$SLURM_NTASKS
echo         SLURM_TIMELIMIT=\$SLURM_TIMELIMIT
echo   SLURM_NTASKS_PER_NODE=\$SLURM_NTASKS_PER_NODE
echo SLURM_NTASKS_PER_SOCKET=\$SLURM_NTASKS_PER_SOCKET
ulimit -s unlimited
ulimit -c unlimited
ulimit -v unlimited

export PMIX_MCA_gds=hash

echo  "STARTING AT \$(date) "
Start=\$(date +%s.%N)
echo \$Start > Timing.degrib
#

# . ${DIRroot}/spack_wps/env_wps.sh
export LD_LIBRARY_PATH=\$LD_LIBRARY_PATH:${HOME}/local/lib64

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

End=\$(date +%s.%N)
echo  "FINISHED AT \$(date) "
echo \$End   >>Timing.degrib
echo \$Start \$End | awk '{print \$2 - \$1" sec"}' >> Timing.degrib
cat Timing.degrib

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
   cp Timing.degrib ${LOGDIR}
   cp namelist.wps degrib_exe.sh ${EXPDIR}/scripts
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
#             Initial conditions (ANALYSIS/ERA5) for MONAN grid
#
###############################################################################

cd ${EXPDIR}

# namelist

sed -e "s,#LABELI#,${start_date},g;s,#GEODAT#,${GEODATA},g" \
	 ${NMLDIR}/namelist.init_atmosphere.TEMPLATE > ./namelist.init_atmosphere

cp ${NMLDIR}/streams.init_atmosphere.TEMPLATE ./streams.init_atmosphere
cp -f ${NMLDIR}/x1.1024002.graph.info.part.${numNucleos} .

# executable
ln -sf ${EXECPATH}/init_atmosphere_model init_atmosphere_model

JobName=ic_monan

pwd
cat > InitAtmos_exe.sh <<EOF0
#!/bin/bash
#SBATCH --job-name=${JobName}
#SBATCH --nodes=${numNodes}             # depends on how many boundary files are available
#SBATCH --partition=${INIT_ATM_PART}      # fron load_monan_app_modules.sh
#SBATCH --tasks-per-node=${numNucleos}     # fron load_monan_app_modules.sh
#SBATCH --time=${JobElapsedTime}
#SBATCH --output=${LOGDIR}/ic.o%j    # File name for standard output
#SBATCH --error=${LOGDIR}/ic.e%j     # File name for standard error output
#
echo     SLURM_JOB_PARTITION=\$SLURM_JOB_PARTITION
echo      SLURM_JOB_NODELIST=\$SLURM_JOB_NODELIST
echo     SLURM_JOB_NUM_NODES=\$SLURM_JOB_NUM_NODES
echo            SLURM_NTASKS=\$SLURM_NTASKS
echo         SLURM_TIMELIMIT=\$SLURM_TIMELIMIT
echo   SLURM_NTASKS_PER_NODE=\$SLURM_NTASKS_PER_NODE
echo SLURM_NTASKS_PER_SOCKET=\$SLURM_NTASKS_PER_SOCKET

export executable=init_atmosphere_model

ulimit -c unlimited
ulimit -v unlimited
ulimit -s unlimited

cd ${DIRroot}
. ${DIRroot}/load_monan_app_modules.sh

cd ${EXPDIR}
rm -f x1.*.init.nc

echo  "STARTING AT \$(date) "
Start=\$(date +%s.%N)
echo \$Start >  ${EXPDIR}/Timing.InitAtmos

time mpirun -np \$SLURM_NTASKS ./\${executable}

End=\$(date +%s.%N)
echo  "FINISHED AT \$(date) "
echo \$End   >> ${EXPDIR}/Timing.InitAtmos
echo \$Start \$End | awk '{print \$2 - \$1" sec"}' >>  ${EXPDIR}/Timing.InitAtmos
cat Timing.InitAtmos 

 mv Timing.InitAtmos log.*.out ${LOGDIR}
 cp namelist.init* streams.init* ${EXPDIR}/scripts
 cp InitAtmos_exe.sh ${EXPDIR}/scripts


date
exit 0
EOF0

chmod +x InitAtmos_exe.sh

else

echo "Benchmark CFSR 2010102300 15 km"
cp -f ${BNDDIR}/x1.* .
cp -f ${NMLDIR}/namelist.atmosphere.BENCH namelist.atmosphere
cp -f ${NMLDIR}/streams.atmosphere.BENCH streams.atmosphere

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

 JobName=MONAN.GNU      
   cores=${numNucleosModel}   # from load_monan_app_modules.sh
   NODES=${numNodesModel}     # from load_monan_app_modules.sh
partName=${ATM_MODEL_PART} # from load_monan_app_modules.sh
wallTime=${sTimeModel}     # from load_monan_app_modules.sh

ln -sf ${EXECPATH}/atmosphere_model .
cp -f ${TBLDIR}/* .

if [ ${EXP} = "ERA5" ]; then
sed -e "s,#LABELI#,${start_date},g" \
         ${NMLDIR}/namelist.atmosphere.TEMPLATE > ./namelist.atmosphere
cp -f ${NMLDIR}/streams.atmosphere.TEMPLATE streams.atmosphere
fi

cp -f ${NMLDIR}/stream_list.atmosphere.* .

if [ ${EXP} = "ERA5" ]; then
 cp -f ${NMLDIR}/x1.1024002.graph.info.part.${cores} .
else
 cp -f ${NMLDIR}/x1.2621442.graph.info.part.${cores} .
fi 

cat > monan_exe.sh <<EOF0
#!/bin/bash
#SBATCH          --nodes=${NODES}
#SBATCH         --ntasks=${cores} 
# BATCH --tasks-per-node=32
#SBATCH      --partition=${partName} 
#SBATCH       --job-name=${JobName}
#SBATCH           --time=${wallTime}        
#SBATCH         --output=${LOGDIR}/monan_model.o%j # File name for standard output
#SBATCH          --error=${LOGDIR}/monan_model.e%j # File name for standard error output

echo     SLURM_JOB_PARTITION=\$SLURM_JOB_PARTITION
echo      SLURM_JOB_NODELIST=\$SLURM_JOB_NODELIST
echo     SLURM_JOB_NUM_NODES=\$SLURM_JOB_NUM_NODES
echo            SLURM_NTASKS=\$SLURM_NTASKS
echo         SLURM_TIMELIMIT=\$SLURM_TIMELIMIT
echo   SLURM_NTASKS_PER_NODE=\$SLURM_NTASKS_PER_NODE
echo SLURM_NTASKS_PER_SOCKET=\$SLURM_NTASKS_PER_SOCKET

export executable=atmosphere_model

cd ${DIRroot}
. ${DIRroot}/load_monan_app_modules.sh

# generic
ulimit -s unlimited

cd ${EXPDIR}

comando="rm -f history.* diag.*"
echo \${comando}; eval \${comando}

Start=\$(date +%s.%N)
echo  "STARTING AT \$(date) "
echo \$Start >  ${EXPDIR}/Timing

comando="time mpirun -np \$SLURM_NTASKS ./\${executable}"
echo \$comando; eval \$comando

End=\$(date +%s.%N)
echo  "FINISHED AT \$(date) "
echo \$End   >> ${EXPDIR}/Timing
echo \$Start \$End | awk '{print \$2 - \$1" sec"}' >>  ${EXPDIR}/Timing
cat ${EXPDIR}/Timing

if [ ! -e "${EXPDIR}/diag.2021-01-02_00.00.00.nc" ]; then
    echo "********* ATENTION ************"
    echo "An error running MONAN occurred. check logs folder"
    echo "File ${EXPDIR}/diag.2021-01-02_00.00.00.nc was not generated."
    exit  1
fi
echo -e  "Script \${0} completed. \n"
  
#
# move dataout, clean up and remove files/links
#

mv log.atmosphere.*.out ${LOGDIR}
cp namelist.atmosphere  ${EXPDIR}/scripts
cp monan_exe.sh         ${EXPDIR}/scripts
cp stream*              ${EXPDIR}/scripts
cp x1.*.init.nc*        ${EXPDIR}/monanprd
cp diag*                ${EXPDIR}/monanprd
cp histor*              ${EXPDIR}/monanprd
mv Timing               ${LOGDIR}/Timing.MONAN
find ${EXPDIR} -maxdepth 1 -type l -exec rm -f {} 

exit 0
EOF0

chmod +x monan_exe.sh

exit 0

#######################################################################
#
#                         Post-processing
#
#######################################################################

cd ${EXPDIR}/postprd

#

exit 0

