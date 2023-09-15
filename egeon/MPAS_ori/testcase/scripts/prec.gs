'reinit';'set display color white';'c'

'set parea 1 9.5 1 7.5'

'set gxout shaded'

'sdfopen surface.nc'
'set mpdset mres'
'set grads off'

'set lon -83.75 -20.05'
'set lat -55.75 14.25'
*'set t 13'
*'pr12=rainc+rainnc'
*'set t 37'
*'pr36=rainc+rainnc'
'set t 25'
'pr24=rainc+rainnc'

'set clevs 0.5 1 2 4 8 16 32 64 128'
'set ccols 0 14 11 5 13 10 7 12 2 6'

*'d pr36-pr12'
'd pr24'
'set gxout contour'
*'d mslp/100'
*'d skip(u10,20);v10'

*'draw title MPAS APCP+36 12Z02JAN2021'
'draw title MPAS APCP+24 00Z02JAN2021'

'printim MPAS.png'

return
