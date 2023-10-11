'reinit';'set display color white';'c'


'set gxout shaded'

'sdfopen surface.nc'
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
'draw title MONAN APCP+24h'

'printim MONAN.png'
'quit'
