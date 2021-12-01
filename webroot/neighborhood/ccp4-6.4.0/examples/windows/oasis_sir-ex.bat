::!\bin\sh

:: Calculate phases from refined model for later comparison

sfall hklin %RNASE%\rnase25.mtz xyzin %RNASE%\rnase.pdb hklout %TEMPRES%\rnase_mod.mtz < %SCRIPTWIN%\oasis_sir1.dat

:: Use sftools to calculate isomorphous difference

sftools < %SCRIPTWIN%\oasis_sir2.dat

oasis hklin %TEMPRES%\rnase_sir.mtz hklout %TEMPRES%\rnase_phase.mtz < %SCRIPTWIN%\oasis_sir3.dat

dm hklin %TEMPRES%\rnase_phase.mtz hklout %TEMPRES%\rnase_dm.mtz < %SCRIPTWIN%\oasis_sir4.dat
