::!\bin\sh

::
:: RUNNABLE EXAMPLE SCRIPT FOR RSTATS
::
::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::


::
::  First run SFALL to get obs. and cal. data
::  from toxd in the same file.
::
::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::

sfall XYZIN %TOXD%\toxd.pdb HKLIN %TOXD%\toxd.mtz HKLOUT %TEMPRES%\toxd_fc < %SCRIPTWIN%\rstats1.dat

::
::  Use RSTATS to scale the Fc's to the Fo's
::
::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::

rstats  HKLIN %TEMPRES%\toxd_fc HKLOUT %TEMPRES%\toxd_sc < %SCRIPTWIN%\rstats2.dat
