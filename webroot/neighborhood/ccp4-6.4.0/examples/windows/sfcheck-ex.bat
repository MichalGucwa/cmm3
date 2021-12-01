::!\bin\sh

:: Example of running SFCHECK 

::sfcheck produces a lot of little files 

cd %TEMPRES%

sfcheck HKLIN %TOXD%\toxd.mtz XYZIN %TOXD%\toxd.pdb  < %SCRIPTWIN%\sfcheck.dat

::the postcript file of intrest is in 
:: %TEMPRES%\sfcheck_XXXX.ps
::

cd %SCRIPTWIN%