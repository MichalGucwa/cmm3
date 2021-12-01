::!\bin\sh
::
::  Example of calculating and interpreting Patterson 
::  uses Au derivative of Green Mamba Dendrotoxin.
::  Single site is determined from Patterson and then is refined
::  in procedure mir_steps.
::  The Patterson is calculated using data scaled by Fhscal as this
::  gives a better solution in this case.
::
::  Updated to use RSPS v4.2 on 20-01-2000.
::

IF NOT EXIST %TEMPRES%\toxd_fhsc.mtz (echo '! run fhscal.exam first' 1>&2 && GOTO :EOF)

fft HKLIN  %TEMPRES%\toxd_fhsc.mtz MAPOUT  %TEMPRES%\toxd_aupatt.map < %SCRIPTWIN%\rsps1.dat

::  RSPS may be run interactively by typing rsps or from a script as in
::  this example
::
::=====================================================================
::
:: example script
::
::!\bin\sh

rsps < %SCRIPTWIN%\rsps2.dat
