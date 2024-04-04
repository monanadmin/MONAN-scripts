#module purge command doesn't working correctly 
module purge
export MODULEPATH=/usr/share/Modules/modulefiles:/etc/modulefiles:/scratch/app/modulos

 netcdfModule="netcdf/4.9.2_openmpi-4.1.6_gnu_sequana"
pnetcdfModule="pnetcdf/1.12.3_openmpi-4.1.6_gnu_sequana"

module load sequana/current
module load    $pnetcdfModule 
module load    $netcdfModule 

module list

comandoA="$(module show ${netcdfModule}  2>&1 |grep " PATH " |awk '{print "export  NETCDF="substr($NF,1,length($NF)-4)}')"
echo $comandoA;  
eval $comandoA;  
echo NETCDF=$NETCDF

comandoA="$(module show ${pnetcdfModule} 2>&1 |grep " PATH " |awk '{print "export  PNETCDF="substr($NF,1,length($NF)-4)}')"
echo $comandoA;  
eval $comandoA;  
echo PNETCDF=$PNETCDF

export LIBS="$LIBS -lstdc++"
export OMP_NUM_THREADS=1

export INIT_ATM_PART=sequana_cpu_dev 
export numNodes=1   # 4 is max value possible to sequana_cpu_dev
export numNucleos=32
export sTime=00:20:00 # 20 minutes is the maximum time to sequana_cpu_dev

function modelParallelOptionA() {
export ATM_MODEL_PART=sequana_cpu_shared
export numNodesModel=4
export numNucleosModel=128
export sTimeModel=03:00:00
}

function modelParallelOptionB() {
export ATM_MODEL_PART=sequana_cpu_shared
export numNodesModel=8
export numNucleosModel=246
export sTimeModel=01:00:00
}


modelParallelOptionB
