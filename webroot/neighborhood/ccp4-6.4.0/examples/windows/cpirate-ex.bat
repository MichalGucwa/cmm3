::!/bin/sh
::
::  PHASE ANALYSIS is done by phistats, if you insist.
::  It will analyse any two sets of phases.
::  Here it is used to check the agreement between MIR phases
::  and PHIcalc.
::  It is probably better to do map correlation.

IF NOT EXIST %TEMPRES%\toxd_phase_mir.mtz (echo '! run the mlphare procedure first' 1>&2 && GOTO :EOF)

na4tomtz hklin %DATA%\1ajr.na4 hklout %TEMPRES%\ref

cpirate -stdin < %SCRIPTWIN%\cpirate1.dat

cfft -stdin < %SCRIPTWIN%\cpirate2.dat
