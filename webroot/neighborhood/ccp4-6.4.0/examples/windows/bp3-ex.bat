::!\bin\sh


:: Phasing the rnase using Pt sites only.
:: See Sevcik, Dodson and Dodson, Acta Cryst. B47 240 (1991)

bp3 HKLIN %RNASE%\rnase25.mtz HKLOUT %TEMPRES%\rnase_phase_mir.mtz < %SCRIPTWIN%\bp3-1.dat

::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
::  example 2
:: wtihdraw double colon if you want to execute all examples
:: bp3 HKLIN %DATA%\gere_MAD_nat_scaleit1.mtz HKLOUT %TEMPRES%\gere_MAD_phase.mtz < %SCRIPTWIN%\bp3-2.dat


::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
::  example 3

:: bp3 HKLIN %TOXD%\toxd.mtz HKLOUT %TEMPRES%\toxd_phase_mir.mtz %SCRIPTWIN%\bp3-3.dat


