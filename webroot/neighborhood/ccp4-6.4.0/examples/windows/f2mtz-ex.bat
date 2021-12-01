::!\bin\sh
::  Standard program for reading ASCII files to MTZ.
::  Number of columns is derived from LABOUT line.
::  Remember all input data must be separated by space unless you
::  specify a FORMAT (as below).
::
:: You will need to run cad too - your data will need to be sorted and
:: may not be in the conventional CCP4 asymmetric unit.
::


IF NOT EXIST %TEMPRES%\toxd.hkl (echo "! run mtz2various.exam first" 1>&2 && GOTO :EOF)

:: this was changed from Xplor format - hope its ok
:: Convert CNS formatted file from mtz2various back to mtz.

f2mtz HKLIN %TEMPRES%\toxd.hkl HKLOUT %TEMPRES%\junk_hkl < %SCRIPTWIN%\f2mtz1.dat

:: Convert file from mtz2various with OUTPUT USER.

f2mtz HKLIN %TEMPRES%\toxd.user HKLOUT %TEMPRES%\junk_user < %SCRIPTWIN%\f2mtz2.dat


:: We now need to correct the dataset information, since we have
:: read in two datasets simultaneously - it would have been better
:: to convert them separately!

cad HKLIN1 %TEMPRES%\junk_user HKLOUT %TEMPRES%\junk_user_1 < %SCRIPTWIN%\f2mtz3.dat


