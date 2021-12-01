::!\bin\sh 
::
::  Plot of molecule and fc map
::

IF NOT EXIST %TEMPRES%\toxd_fc.map ( echo "! run sf_calc first" 1>&2 && GOTO :EOF)

npo XYZIN1 %TOXD%\toxd.pdb MAPIN %TEMPRES%\toxd_fc.map PLOT %TEMPRES%\z.plot < %SCRIPTWIN%\npo1.dat

::
::map\atoms example 2
::====================

npo mapin %TEMPRES%\toxd_fc.map xyzin1 %TOXD%\toxd.pdb plot  %TEMPRES%\apo.plt < %SCRIPTWIN%\npo2.dat

:::::: now convert to PostScript

pltdev -dev ps -aut -pen c -i %TEMPRES%\z.plot -o %TEMPRES%\plot84.ps 
