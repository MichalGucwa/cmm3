::!/bin/sh

:: So output files will not be in this directory
cd %TEMPRES%
::
:: data from cris
::
findncs < %SCRIPTWIN%/findncs.dat
::

cd %SCRIPTWIN%