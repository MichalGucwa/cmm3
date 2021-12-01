::!\bin\sh

::   Gives tables of RMS B factors for MAIN and SIDE chains.
::   Allows you to truncate Main and SIDE chain B values to given limits.
::   All keywords can be defaulted.

baverage XYZIN %TOXD%\toxd.pdb RMSTAB %TEMPRES%\rmsbs.tab XYZOUT %TEMPRES%\junk.pdb < %SCRIPTWIN\%baverage.dat


 

