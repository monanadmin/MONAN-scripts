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

START_DATE_YYYYMMDD="${DATA_INIT:0:4}-${DATA_INIT:4:2}-${DATA_INIT:6:2}"
START_HH="${DATA_INIT:8:2}"
END_DATE_YYYYMMDD="${DATA_END:0:4}-${DATA_END:4:2}-${DATA_END:6:2}"
END_HH="${DATA_END:8:2}"

rm -f include_fields
cp include_fields.diag include_fields
rm -f latlon.nc surface.nc

./convert_mpas ../monanprd/x1.${RESOLUTION}.init.nc ../monanprd/diag*nc
cdo settunits,hours -settaxis,${START_DATE_YYYYMMDD},${START_HH}:00,1hour latlon.nc surface.nc

rm -f latlon.nc

#
# 2. Timeseries for History fields
#

rm -f include_fields wind+pw_sfc.nc
cp include_fields.history include_fields

./convert_mpas ../monanprd/x1.${RESOLUTION}.init.nc ../monanprd/history.*.nc

cdo settunits,hours -settaxis,${START_DATE_YYYYMMDD},${START_HH}:00,3hour latlon.nc wind+pw_sfc.nc

# rm -f latlon.nc 

#
# 3.  
#
./convert_mpas ../monanprd/history.${END_DATE_YYYYMMDD}_${END_HH}.00.00.nc

#cdo -setreftime,1900-01-01,00:00:00,1day -setdate,1900-01-01 -setcalendar,standard latlon.nc history.2021-01-04_00.00.00.nc

# 24h
cdo settunits,hours -settaxis,${END_DATE_YYYYMMDD},${END_HH}:00,3hour latlon.nc history.${END_DATE_YYYYMMDD}_${END_HH}.00.00.nc

rm -f latlon.nc

exit 0
