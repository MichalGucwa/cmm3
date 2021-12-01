::!\bin\sh
::
:: Example of running Vecref - NB scaling should be done with 
:: Fhscal first and vf000 term output by Fhscal should be used
:: in Patterson calculation.
::
:: Use Fhscal to scale native and derivative data

fhscal hklin %TOXD%\toxd.mtz hklout %TEMPRES%\toxd_fhsc.mtz < %SCRIPTWIN%\vecref1.dat

::
::  Calculate Patterson

fft HKLIN  %TEMPRES%\toxd_fhsc.mtz MAPOUT  %TEMPRES%\toxd_aupatt.map < %SCRIPTWIN%\vecref2.dat

:: Use vecref to refine sites determined using RSPS (see rsps.exam)
::

vecref MAPIN %TEMPRES%\toxd_aupatt.map ATOUT %TEMPRES%\toxd_vecref.data < %SCRIPTWIN%\vecref3.dat

