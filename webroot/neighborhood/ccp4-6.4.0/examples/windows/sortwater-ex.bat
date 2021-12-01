::!\bin\csh -f

::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:: 
::  Simple Example for SORTWATER
::
::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::

::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:: ASSIGN WATERS TO PROTEIN CHAINS
::
:: Waters associated with chain A will be assigned
:: to chain U; those associated with chain B will
:: be assigned to chain V.

sortwater XYZIN %TOXD%\toxd.pdb XYZOUT %TEMPRES%\toxd_sw.pdb < %SCRIPTWIN%\sortwater.dat


