::!\bin\sh
::
::  PHASE ANALYSIS is done by phistats, if you insist.
::  It will analyse any two sets of phases.
::  Here it is used to check the agreement between MIR phases
::  and PHIcalc.
::  It is probably better to do map correlation.


IF NOT EXIST %TEMPRES%\toxd_phase_mir.mtz  (echo "! run the mlphare procedure first" 1>&2 && GOTO :EOF)

::  Calculate structure factors.
::  File toxd_mir.mtz  can be generated using mlphare.com
sfall HKLIN %TEMPRES%\toxd_phase_mir.mtz HKLOUT %TEMPRES%\toxd_sf_mir.mtz XYZIN %TOXD%\toxd.pdb < %SCRIPTWIN%\phase_analysis1.dat

:: Phase analysis 
::  Assign Weight 1 to FOM, Weight 2 to FC magnitude.
::
::          Analyse two sets of phases (no phase combination)

phistats hklin %TEMPRES%\toxd_sf_mir < %SCRIPTWIN%\phase_analysis2.dat

::  Optional extra - combine these phases..
::
::         Set option to combine phase information from
:: eg isomorphous  replacement with partial structure

sigmaa hklin %TEMPRES%\toxd_sf_mir hklout %TEMPRES%\junk <%SCRIPTWIN%\phase_analysis3.dat
