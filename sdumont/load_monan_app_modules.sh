#module purge command doesn't working correctly 
module purge
export MODULEPATH=/usr/share/Modules/modulefiles:/etc/modulefiles:/scratch/app/modulos


COMPILER=gnu
export COMPILER

echo COMPILER=$COMPILER; 

cdoModule="cdo/2.4.0_openmpi-4.1.6_sequana"

function modulosI() {
 netcdfModule="netcdf/4.7_intel_2020_sequana"
pnetcdfModule="pnetcdf/1.12.3_intel-2020_sequana"

}

function modulosG(){
 netcdfModule="netcdf/4.8.1_hdf5-threadsafe-HL_openmpi-4.1.6_gnu_sequana"
pnetcdfModule="pnetcdf/1.12.3_hdf5-threadsafe-HL_openmpi-4.1.6_gnu_sequana"
  export LIBS="$LIBS -lstdc++"
}

if [ "$COMPILER" == "gnu" ] ; then
 echo GNU compiler;
  modulosG
 else
 echo INTEL compiler;
  modulosI
 fi

  comando="module load sequana/current"
  echo $comando;  eval $comando;  
  comando="module load $pnetcdfModule"
  echo $comando;  eval $comando;  
  comando="module load $netcdfModule"
  echo $comando;  eval $comando;  
  #comando="module load $cdoModule"; echo $comando;  eval $comando;  
  comando="module list"; echo $comando;  eval $comando;  
  
  export NETCDF=$(nc-config --prefix)
  echo NETCDF=$NETCDF
  export PNETCDF=$(pnetcdf-config --prefix)
  echo PNETCDF=$PNETCDF

export OMP_NUM_THREADS=1

export INIT_ATM_PART=sequana_cpu_shared 
export INIT_ATM_PART=sequana_cpu_dev 
export      numNodes=2   # 4 is max value possible to sequana_cpu_dev
export    numNucleos=32
export         sTime=00:20:00 # 20 minutes is the maximum time to sequana_cpu_dev

function modelParallelOptionA() {
export  ATM_MODEL_PART=sequana_cpu_shared; export sTimeModel=04:00:00
export  ATM_MODEL_PART=sequana_cpu_dev;    export sTimeModel=00:20:00
export   numNodesModel=4
export numNucleosModel=64
}

function modelParallelOptionB() {
export  ATM_MODEL_PART=sequana_cpu_shared
export      sTimeModel=00:30:00
export   numNodesModel=2
export numNucleosModel=48
}

modelParallelOptionA

