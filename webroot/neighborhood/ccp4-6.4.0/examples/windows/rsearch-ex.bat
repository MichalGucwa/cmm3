::!\bin\sh
::
:: Rfactor search to solve molecular replacement problem.
:: 
:: initial procedure same as tffc_procedure

IF NOT EXIST %TEMPRES%\toxd_cad.mtz (echo "! run tffc_procedure first" 1>&2 && GOTO :EOF)

::
::   Optional step: 
::  Run scaleit to put FP onto the same scale as one of the FCPARTs.
::  Remember you will need to use resolution required for rsearch.
::

scaleit HKLIN %TEMPRES%\toxd_cad.mtz HKLOUT %TEMPRES%\toxd_cad_sc.mtz < %SCRIPTWIN%\rsearch1.dat

::Rfactor search
::Input mtz hkl list  of fobs fc1 ac1  fc2 ac2.....
::R factor requires Fobs scaled to fc - I run it once and get
::an output scale...
::Correlation Coeff is meant to be independent of scale..

rsearch HKLIN %TEMPRES%\toxd_cad_sc.mtz MAPOUT %TEMPRES%\toxd.map SEARCHSAVE %TEMPRES%\searchsave.tmp	< %SCRIPTWIN%\rsearch2.dat

