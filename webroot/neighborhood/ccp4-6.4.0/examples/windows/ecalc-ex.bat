::!\bin\sh 

::
::  Generate Es from input Fs
::

::  Minimal example:

ecalc hklin %TOXD%\toxd.mtz hklout %TEMPRES%\toxd_e.mtz < %SCRIPTWIN%\ecalc1.dat

::  Generating Es from anomalous data

ecalc hklin %TOXD%\toxd.mtz hklout %TEMPRES%\toxd_e_anom.mtz < %SCRIPTWIN%\ecalc2.dat


::  Example preparing input for Shake-and-Bake:

ecalc hklin %TOXD%\toxd.mtz hklout %TEMPRES%\toxd_snb.hkl < %SCRIPTWIN%\ecalc3.dat

:: Extract sample results for testing purposes - these can
:: be compared with runs with different versions or on different
:: platforms

echo " " >> %TEMPRES%\sample_results
echo " *** ecalc.exam *** " >> %TEMPRES%\sample_results
echo " " >> %TEMPRES%\sample_results

::mtzdmp %TEMPRES%\toxd_e.mtz | find "F  F_ecalc"  >> %TEMPRES%\sample_results
::mtzdmp %TEMPRES%\toxd_e.mtz | find "E  E"  >> %TEMPRES%\sample_results
::mtzdmp %TEMPRES%\toxd_e.mtz | find "Q  SIGE"  >> %TEMPRES%\sample_results
