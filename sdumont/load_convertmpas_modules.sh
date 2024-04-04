#module purge command doesn't working correctly
module purge
export MODULEPATH=/usr/share/Modules/modulefiles:/etc/modulefiles:/scratch/app/modulos
 netcdfModule="netcdf/4.9.2_openmpi-4.1.6_gnu_sequana"

module load sequana/current
module load    $netcdfModule 
module list

comandoA="$(module show ${netcdfModule}  2>&1 |grep " PATH " |awk '{print "export  NETCDF="substr($NF,1,length($NF)-4)}')"
echo $comandoA;  
eval $comandoA;  
echo NETCDF=$NETCDF

