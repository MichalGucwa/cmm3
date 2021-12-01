::!\bin\sh 
::

hklplot HKLIN  %TOXD%\toxd.mtz PLOT  %TEMPRES%\plothkl.plot < %SCRIPTWIN%\hklplot.dat

pltdev -dev ps -aut -i %TEMPRES%\plothkl.plot -o %TEMPRES%\plot84.ps
::
