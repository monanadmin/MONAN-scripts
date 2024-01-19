#!/bin/bash
#-----------------------------------------------------------------------------#
#BOP
#
# !SCRIPT: static
#
# !DESCRIPTION: Script para criar topografia, land use e variáveis estáticas
#
# !CALLING SEQUENCE:
#
#     ./static.sh DIRECTORY RESOLUTION
#           DIRECTORY: EXP_NAME, ERA5, CFSR, etc.
#           RESOLUTION: 1024002  (24 km)
#
# For benchmark:
#     ./static.sh ERA5 1024002
#
# !REVISION HISTORY: 
#
# !REMARKS:
#
#EOP
#-----------------------------------------------------------------------------!
#EOC

function usage(){
   sed -n '/^# !CALLING SEQUENCE:/,/^# !/{p}' static.sh | head -n -1
}

#
# Check input args
#

if [ $# -ne 2 ]; then
   usage
   exit 1
fi

#
# Args
#
   EXP=${1}
   RES=${2}
#
# Paths
#

#---
HSTMAQ=$(hostname)
BASEDIR=$(dirname $(pwd))
DATADIR=${BASEDIR}/data
TBLDIR=${BASEDIR}/tables
NMLDIR=${BASEDIR}/namelist
GEODATA=${BASEDIR}/data/WPS_GEOG/
EXECFILEPATH=${BASEDIR}/../exec
SCRIPTFILEPATH=${BASEDIR}/runs
STATICPATH=${SCRIPTFILEPATH}/${EXP}/static


#
# Criando diretorio dados Estaticos
#

if [ ! -d ${STATICPATH} ]; then
  mkdir -p ${STATICPATH}/logs
fi

cd ${STATICPATH}

ln -sf ${TBLDIR}/* .
ln -sf ${DATADIR}/meshes/x1.${RES}.grid.nc .

ln -sf ${EXECFILEPATH}/init_atmosphere_model .

sed -e "s,#GEODAT#,${GEODATA},g;s,#RES#,${RES},g" \
	${NMLDIR}/namelist.init_atmosphere.STATIC \
       > ${STATICPATH}/namelist.init_atmosphere

sed -e "s,#RES#,${RES},g" \
       	${NMLDIR}/streams.init_atmosphere.STATIC \
	> ${STATICPATH}/streams.init_atmosphere


cores=32

ln -sf ${NMLDIR}/x1.${RES}.graph.info.part.${cores} .

#
# make submission job
#

cat > ${STATICPATH}/make_static.sh << EOF0
#!/bin/bash
#SBATCH --job-name=static
#SBATCH --nodes=1              # Specify number of nodes
#SBATCH --ntasks=${cores}             
#SBATCH --tasks-per-node=${cores}     # Specify number of (MPI) tasks on each node
#SBATCH --partition=batch
#SBATCH --time=02:00:00        # Set a limit on the total run time
#SBATCH --output=${STATICPATH}/logs/my_job.o%j    # File name for standard output
#SBATCH --error=${STATICPATH}/logs/my_job.e%j     # File name for standard error output
#SBATCH --mem=500000

executable=init_atmosphere_model

ulimit -s unlimited
ulimit -c unlimited
ulimit -v unlimited

cd ${BASEDIR}/../..
. ${BASEDIR}/../../load_monan_app_modules.sh

cd ${STATICPATH}

echo  "STARTING AT \`date\` "
Start=\`date +%s.%N\`
echo \$Start > ${STATICPATH}/Timing

date
time mpirun -np \$SLURM_NTASKS -env UCX_NET_DEVICES=mlx5_0:1 -genvall ./\${executable}

End=\`date +%s.%N\`
echo  "FINISHED AT \`date\` "
echo \$End   >> ${STATICPATH}/Timing
echo \$Start \$End | awk '{print \$2 - \$1" sec"}' >> ${STATICPATH}/Timing

grep "Finished running" log.init_atmosphere.0000.out >& /dev/null

if [ \$? -ne 0 ]; then
   echo "  BUMMER: Static generation failed for some yet unknown reason."
   echo " "
   tail -10 ${STATICPATH}/log.init_atmosphere.0000.out
   echo " "
   exit 21
fi
   echo "  ####################################"
   echo "  ### Static completed - \$(date) ####"
   echo "  ####################################"
   echo " "
#
# clean up and remove links
#

mv log.init_atmosphere.0000.out ${STATICPATH}/logs
mv Timing  ${STATICPATH}/logs

find ${STATICPATH} -maxdepth 1 -type l -exec rm -f {} \;

date
exit 0
EOF0

chmod +x ${STATICPATH}/make_static.sh

