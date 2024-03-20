#!/bin/bash
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
#        ./run_monan_gnu.egeon EXP_NAME RES LABELI FCST
#
#           o EXP_NAME : Forcing: ERA5, CFSR, GFS, etc.
#           o RES      : Resolution: 1024002 (24km), 2621442
#           o LABELI   : Initial: date 2015030600
#           o FCST     : Forecast: 24, 36, 72, 84, etc. [hours]
#           o LABELF   : Final: = LABELI + FCST
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

# TODO - revision history - start from last GAM rev - this is a different code purpose

function usage(){
   sed -n '/^# !CALLING SEQUENCE:/,/^# !/{p}' ./run_monan_gnu.egeon | head -n -1
}

#
# Verificando argumentos de entrada
#

if [ $# -ne 5 ]; then
   usage
   exit 1
fi

export HUGETLB_VERBOSE=0

#
# pegando argumentos
#
EXP=${1}
RES=${2}
LABELI=${3} 
FCST=${4}
LABELF=${5}

start_date=${LABELI:0:4}-${LABELI:4:2}-${LABELI:6:2}_${LABELI:8:2}:00:00

EXPDIR=${RUNDIR}/${EXP}/${LABELI}
LOGDIR=${EXPDIR}/logs

#
# Initial Conditions: 
#
# GFS operacional                    GFS
# GFS analysis                       FNL
# ERA5 reanalysis                    ERA5
#

#OPERDIR=${BASEDIR}/data/${EXP}
OPERDIR=/oper/dados/ioper/tempo/${EXP}

#BNDDIR=$OPERDIR/${LABELI:0:10}
BNDDIR=$OPERDIR/0p25/brutos/${LABELI:0:4}/${LABELI:4:2}/${LABELI:6:2}/${LABELI:8:2}

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
   mkdir -p ${EXPDIR}/monanprd
   mkdir -p ${EXPDIR}/wpsprd
   mkdir -p ${EXPDIR}/postprd
fi
#

cd ${EXPDIR}

##############################################################################
#
#                               links
#
##############################################################################


ln -sf ${BASEDIR}/runs/${EXP}/static/*.nc .

cd ${EXPDIR}/wpsprd

#

echo "FORECAST "${LABELI}

ln -sf ${TBLDIR}/Vtable.GFS ./Vtable

cp ${SCRDIR}/link_grib.csh .

ln -sf ${EXECPATH}/ungrib.exe                    .

#ln -sf ${BNDDIR}/*.grib2 .
#ln -sf ${BNDDIR}/gfs.t00z.pgrb2.0p25.f000.${LABELI}.grib2 .
cp -rf ${BNDDIR}/gfs.t00z.pgrb2.0p25.f000.${LABELI}.grib2 .


#
# scripts
#
JobName=gfs4monan

cat > degrib_exe.sh << EOF0
#!/bin/bash
#SBATCH --job-name=${JobName}
#SBATCH --nodes=1
#SBATCH --partition=batch
#SBATCH --tasks-per-node=1                      # ic for benchmark
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

export LD_LIBRARY_PATH=\$LD_LIBRARY_PATH:${HOME}/local/lib64

ldd ungrib.exe

cd $EXPDIR/wpsprd

if [ -e namelist.wps ]; then rm -f namelist.wps; fi

#
# Now surface and upper air atmospheric variables
#
rm GRIBFILE.* namelist.wps

sed -e "s,#LABELI#,${start_date},g;s,#PREFIX#,GFS,g" \
	${NMLDIR}/namelist.wps.TEMPLATE > ./namelist.wps

./link_grib.csh gfs.t00z.pgrb2.0p25.f000.${LABELI}.grib2

mpirun -np 1 ./ungrib.exe

echo ${start_date:0:13}

rm -f GRIBFILE.*
rm -f gfs.t00z.pgrb2.0p25.f000.${LABELI}.grib2

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
   ln -sf wpsprd/GFS\:${start_date:0:13} .
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
ln -sf ${NMLDIR}/x1.${RES}.graph.info.part.32 .

# executable
ln -sf ${EXECPATH}/init_atmosphere_model init_atmosphere_model

JobName=ic_monan

cat > InitAtmos_exe.sh <<EOF0
#!/bin/bash
#SBATCH --job-name=${JobName}
#SBATCH --nodes=1                         # depends on how many boundary files are available
#SBATCH --partition=batch 
#SBATCH --tasks-per-node=32               # only for benchmark
#SBATCH --time=${JobElapsedTime}
#SBATCH --output=${LOGDIR}/my_job_ic.o%j    # File name for standard output
#SBATCH --error=${LOGDIR}/my_job_ic.e%j     # File name for standard error output
#SBATCH --exclusive

export executable=init_atmosphere_model

ulimit -c unlimited
ulimit -v unlimited
ulimit -s unlimited

cd ${DIRroot}
. ${DIRroot}/load_monan_app_modules.sh

cd ${EXPDIR}

echo  "STARTING AT \`date\` "
Start=\`date +%s.%N\`
echo \$Start >  ${EXPDIR}/Timing.InitAtmos

time mpirun -np \$SLURM_NTASKS -env UCX_NET_DEVICES=mlx5_0:1 -genvall ./\${executable}

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

###############################################################

chmod +x InitAtmos_exe.sh


###############################################################################
#
#                             Rodando o Modelo
#
###############################################################################

#
# Configuracoes para o modelo (pre-operacao/demo)
#

cd ${EXPDIR}

JobName=MONAN.GNU        # Nome do Job
cores=1024

ln -sf ${EXECPATH}/atmosphere_model .
ln -sf ${TBLDIR}/* .

if [ ${EXP} = "GFS" ]; then
sed -e "s,#LABELI#,${start_date},g" \
         ${NMLDIR}/namelist.atmosphere.TEMPLATE > ./namelist.atmosphere
cp ${NMLDIR}/streams.atmosphere.TEMPLATE streams.atmosphere
fi

cp ${NMLDIR}/stream_list.atmosphere.* .

ln -sf ${NMLDIR}/x1.${RES}.graph.info.part.${cores} .

cat > monan_exe.sh <<EOF0
#!/bin/bash
#SBATCH --nodes=16
#SBATCH --ntasks=${cores}
#SBATCH --tasks-per-node=64
#SBATCH --partition=batch
#SBATCH --job-name=${JobName}
#SBATCH --time=4:00:00         
#SBATCH --output=${LOGDIR}/my_job_monan.o%j   # File name for standard output
#SBATCH --error=${LOGDIR}/my_job_monan.e%j    # File name for standard error output
#SBATCH --exclusive

export executable=atmosphere_model

cd ${DIRroot}
. ${DIRroot}/load_monan_app_modules.sh

# generic
ulimit -s unlimited

cd ${EXPDIR}

echo \$SLURM_JOB_NUM_NODES

echo  "STARTING AT \`date\` "
Start=\`date +%s.%N\`
echo \$Start >  ${EXPDIR}/Timing

time mpirun -np \$SLURM_NTASKS -env UCX_NET_DEVICES=mlx5_0:1 -genvall ./\${executable}

End=\`date +%s.%N\`
echo  "FINISHED AT \`date\` "
echo \$End   >> ${EXPDIR}/Timing
echo \$Start \$End | awk '{print \$2 - \$1" sec"}' >>  ${EXPDIR}/Timing

#
# move dataout, clean up and remove files/links
#

mv log.atmosphere.*.out ${LOGDIR}
mv log.atmosphere.*.err ${LOGDIR}
cp -f namelist.atmosphere ${EXPDIR}/scripts
cp -f monan_exe.sh ${EXPDIR}/scripts
cp -f stream* ${EXPDIR}/scripts
mv x1.*.init.nc ${EXPDIR}/monanprd
ln -sf ${EXPDIR}/monanprd/x1.${RES}.init.nc ${EXPDIR}
mv diag* ${EXPDIR}/monanprd
mv histor* ${EXPDIR}/monanprd
mv Timing ${LOGDIR}/Timing.MONAN
#find ${EXPDIR} -maxdepth 1 -type l -exec rm -f {} \;
#rm -f namelist.atmosphere
#rm -f monan_exe.sh
#rm -f streams*
#if [ ! -e "${EXPDIR}/monanprd/x1.${RES}.init.nc" ]; then
#    cp -f x1.*.init.nc* ${EXPDIR}/monanprd
#fi


exit 0
EOF0

###############################################################

chmod +x monan_exe.sh


#######################################################################
#
#                         Post-processing
#
#######################################################################

#
# Configuring post-processing
#

# EGK: TODO change this export location
export LOG_FILE=${EXPDIR}/postprd/logs/pos.out

START_DATE_YYYYMMDD=${LABELI:0:4}-${LABELI:4:2}-${LABELI:6:2}

# copy convert_mpas from MONAN/exec to testcase
rm -f ${EXPDIR}/postprd/convert_mpas
ln -s ${EXECPATH}/convert_mpas ${EXPDIR}/postprd

# copy from repository to testcase
#cp ${SCRDIR}/prec.gs ${EXPDIR}/postprd/prec.gs
cp ${SCRDIR}/ngrid2latlon.sh ${EXPDIR}/postprd/ngrid2latlon.sh
cp ${SCRDIR}/include* ${EXPDIR}/postprd/.          # choice only some variables
cp ${SCRDIR}/target* ${EXPDIR}/postprd/.           # regrid for regions
cp ${BASEDIR}/NCL/*.ncl ${EXPDIR}/postprd/.        # example NCL script

# creating log dir
mkdir -p ${EXPDIR}/postprd/logs

#

cd ${EXPDIR}/postprd


cat > prec.gs <<EOF0

'reinit';'set display color white';'c'
  

'set gxout shaded'

'sdfopen diagnostics_${START_DATE_YYYYMMDD}.nc'
'set mpdset mres'
'set grads off'

'set lon -83.75 -20.05'
'set lat -55.75 14.25'
'set t 1'
'pr1=rainc+rainnc'
'set t 25'
'pr25=rainc+rainnc'

'set clevs 0.5 1 2 4 8 16 32 64 128'
'set ccols 0 14 11 5 13 10 7 12 2 6'

'd pr25-pr1'
'set gxout contour'

'cbar'
'draw title MONAN_${START_DATE_YYYYMMDD} APCP+24h'

'printim MONAN.png'
'quit'

EOF0

cat > PostAtmos_exe.sh <<EOF0
#!/bin/bash
#SBATCH --job-name=PostAtmos
#SBATCH --nodes=1
#SBATCH --partition=batch 
#SBATCH --tasks-per-node=1
#SBATCH --time=4:00:00
#SBATCH --output=${LOGDIR}/my_job_pa.o%j    # File name for standard output
#SBATCH --error=${LOGDIR}/my_job_pa.e%j     # File name for standard error output
#SBATCH --exclusive

module load netcdf 
module load netcdf-fortran 
module load cdo-2.0.4-gcc-9.4.0-bjulvnd
module load opengrads-2.2.1

rm -f ${LOG_FILE} 
echo -e  "Executing post processing...\n" >> ${LOG_FILE} 2>&1

# runs ./ngrid2latlon.sh
${EXPDIR}/postprd/ngrid2latlon.sh ${RES} ${LABELI} ${LABELF} >> ${LOG_FILE} 2>&1

# runs prec.gs
grads -bpcx "run ${EXPDIR}/postprd/prec.gs" >> ${LOG_FILE} 2>&1

#cdo hourmean diagnostics_${START_DATE_YYYYMMDD}.nc mean.nc >> ${LOG_FILE} 2>&1

#
# move dataout, clean up and remove files/links
#

#echo -e  "Moving dataout, cleaning up and removing files/links...\n" >> ${EXPDIR}/logs/pos.out 2>&1
#
#mv ${EXPDIR}/namelist.atmosphere ${EXPDIR}/scripts
#mv ${EXPDIR}/monan_exe.sh ${EXPDIR}/scripts
#mv ${EXPDIR}/stream* ${EXPDIR}/scripts
#find ${EXPDIR} -maxdepth 1 -type l -exec rm -f {} \;
## EGK: TODO Are the copies above needed?
##cp -f  ${EXPDIR}/postprd/PostAtmos_exe.sh ${EXPDIR}/scripts
##cp -f  ${EXPDIR}/postprd/include_fields ${EXPDIR}/scripts
##cp -f  ${EXPDIR}/postprd/prec.gs ${EXPDIR}/scripts
##cp -f  ${EXPDIR}/postprd/ngrid2latlon.sh ${EXPDIR}/scripts


exit 0
EOF0

chmod +x PostAtmos_exe.sh

cat > Compress_exe.sh <<EOF0
#!/bin/bash
#SBATCH --job-name=Compress
#SBATCH --nodes=1
#SBATCH --partition=PESQ3 
#SBATCH --tasks-per-node=1
#SBATCH --time=24:00:00
#SBATCH --output=${LOGDIR}/my_job_compress.o%j    # File name for standard output
#SBATCH --error=${LOGDIR}/my_job_compress.e%j     # File name for standard error output
#SBATCH --exclusive

echo -e  "Compressing post processed diagnostics file...\n" >> ${LOG_FILE} 2>&1
tar -cf - diagnostics_${START_DATE_YYYYMMDD}.nc | xz -9 -c - > diagnostics_${START_DATE_YYYYMMDD}.tar.xz

#echo -e  "Compressing all /monanprd/diag*.nc files...\n" >> ${LOG_FILE} 2>&1
#tar -cf - ${EXPDIR}/monanprd | xz -9 -c - > monanprd_${START_DATE_YYYYMMDD}.tar.xz

exit 0
EOF0

chmod +x Compress_exe.sh

exit

