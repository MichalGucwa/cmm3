::!\bin\sh

::
:: Kraut scaling of derivative data. Needed for vector refinement (VECREF)

fhscal hklin %TOXD%\toxd.mtz hklout %TEMPRES%\toxd_fhsc.mtz < %SCRIPTWIN%\fhscal1.dat

::
:: to analyse the derivative run scaleit with the analyse option

scaleit HKLIN %TEMPRES%\toxd_fhsc.mtz < %SCRIPTWIN%\fhscal2.dat

::
:: Repeat with AUTO keyword as a test

fhscal hklin %TOXD%\toxd.mtz hklout %TEMPRES%\toxd_fhsc_auto.mtz < %SCRIPTWIN%\fhscal3.dat

echo "\n Diffing output files.... \n"

::mtzdmp %TEMPRES%\toxd_fhsc.mtz > %TEMPRES%\toxd_fhsc.dmp
::mtzdmp %TEMPRES%\toxd_fhsc_auto.mtz > %TEMPRES%\toxd_fhsc_auto.dmp

::if comp %TEMPRES%\toxd_fhsc.dmp %TEMPRES%\toxd_fhsc_auto.dmp (echo)
