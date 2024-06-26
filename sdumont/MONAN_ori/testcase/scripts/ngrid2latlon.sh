#!/bin/bash 
#
# 1. Timeseries for Diagnostic fields
#

echo --------- em $0  ----
rm -f include_fields
cp include_fields.diag include_fields
rm -f latlon.nc surface.nc

RES=40962
RES=1024002
pwd
comando="./convert_mpas ../monanprd/x1.$RES.init.nc   ../monanprd/diag*nc"
echo $comando; eval $comando;
date
comando="pwd; ls -ltr \*.nc |grep -v \"diag\|hist\""
echo $comando; eval $comando;
comando="ncdump -h latlon.nc"
echo $comando; eval $comando;

errCode=$?; if [ $errCode -ne 0 ]; then echo aborted at ngrid2latlon.sh, A!! error $errCode ; exit $errCode; fi

(cd ../monanprd/; pwd; ls -ltr)

comando="cdo settunits,hours -settaxis,2021-01-01,00:00,1hour latlon.nc surface.nc"
#echo $comando; eval $comando;
date
ls -ltr *.nc |grep -v "diag\|hist"
#exit 0
rm -f latlon.nc
#
# 2. Timeseries for History fields
#

rm -f include_fields wind+pw_sfc.nc
cp include_fields.history include_fields
comando="./convert_mpas ../monanprd/x1.$RES.init.nc   ../monanprd/history.*.nc"
echo $comando; eval $comando;
date
ls -ltr *.nc |grep -v "diag\|hist"
errCode=$?; if [ $errCode -ne 0 ]; then echo aborted at ngrid2latlon.sh, B!! error $errCode ; exit $errCode; fi

comando="cdo settunits,hours -settaxis,2021-01-01,00:00,3hour latlon.nc wind+pw_sfc.nc"
#echo $comando; eval $comando;
date
#ls -ltr *.nc |grep -v "diag\|hist"
#rm -f latlon.nc 

#
# 3.  
#
echo " alteracoes pela redução do tempo de processamento"
#  modifySimulationTime
comando="./convert_mpas ../monanprd/history.2021-01-02_00.00.00.nc"
comando="./convert_mpas ../monanprd/history.2021-01-01_03.00.00.nc"
echo $comando; eval $comando;
errCode=$?; if [ $errCode -ne 0 ]; then echo aborted at ngrid2latlon.sh, C!! error $errCode ; exit $errCode; fi
date
pwd
comando="ls -ltr \*.nc |grep -v \"diag\|hist\""
echo $comando; eval $comando;

comando="cdo -setreftime,1900-01-01,00:00:00,1day -setdate,1900-01-01 -setcalendar,standard latlon.nc history.2021-01-02_00.00.00.nc"
comando="cdo -setreftime,1900-01-01,00:00:00,1day -setdate,1900-01-01 -setcalendar,standard latlon.nc history.2021-01-01_03.00.00.nc"
#echo $comando; eval $comando;

# 24h
#cdo settunits,hours -settaxis,2021-01-02,00:00,3hour latlon.nc history.2021-01-02_00.00.00.nc
#cdo settunits,hours -settaxis,2021-01-02,00:00,3hour latlon.nc history.2021-01-01_03.00.00.nc
date
#ls -ltr *.nc |grep -v "diag\|hist"
#rm -f latlon.nc

