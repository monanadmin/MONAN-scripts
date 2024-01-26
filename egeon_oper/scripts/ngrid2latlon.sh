#!/bin/bash 
#
# 1. Timeseries for Diagnostic fields
#
#
# Check input args
#

if [ $# -ne 3 ]; then
    echo "wrong num of parameters in calling ngrid2latlon"
    exit -1
fi

RESOLUTION=${1}
DATA_INIT=${2}
DATA_END=${3}

#export dataf=`date -d "${datai:0:8} ${hh}:00 ${FCST} hours" +"%Y%m%d%H"`
#export final_date=${dataf:0:4}-${dataf:4:2}-${dataf:6:2}_${dataf:8:2}.00.00
#start_date=${LABELI:0:4}-${LABELI:4:2}-${LABELI:6:2}_${LABELI:8:2}:00:00
START_DATE_YYYYMMDD = "${DATA_INIT:0:4}-${DATA_INIT:4:2}-${DATA_INIT:6:2}"
START_HH_MM = "${DATA_INIT:8:2}:00:00"

END_DATE_YYYYMMDD = "${DATA_END:0:4}-${DATA_END:4:2}-${DATA_END:6:2}"
END_HH_MM = "${DATA_END:8:2}:00:00"

rm -f include_fields
cp include_fields.diag include_fields
rm -f latlon.nc surface.nc

./convert_mpas ../monanprd/x1.${RESOLUTION}.init.nc ../monanprd/diag*nc

cdo settunits,hours -settaxis,${START_DATE_YYYYMMDD},${START_HH_MM},1hour latlon.nc surface.nc

rm -f latlon.nc

#
# 2. Timeseries for History fields
#

rm -f include_fields wind+pw_sfc.nc
cp include_fields.history include_fields
./convert_mpas ../monanprd/x1.${RESOLUTION}.init.nc ../monanprd/history.*.nc

cdo settunits,hours -settaxis,${START_DATE_YYYYMMDD},${START_HH_MM},3hour latlon.nc wind+pw_sfc.nc

rm -f latlon.nc 

#
# 3.  
#
./convert_mpas ../monanprd/history.${END_DATE_YYYYMMDD}_${END_HH_MM}.00.nc

#cdo -setreftime,1900-01-01,00:00:00,1day -setdate,1900-01-01 -setcalendar,standard latlon.nc history.2021-01-04_00.00.00.nc

# 24h
cdo settunits,hours -settaxis,${END_DATE_YYYYMMDD},${END_HH_MM},3hour latlon.nc history.${END_DATE_YYYYMMDD}_${END_HH_MM}.00.nc

rm -f latlon.nc

exit 0
