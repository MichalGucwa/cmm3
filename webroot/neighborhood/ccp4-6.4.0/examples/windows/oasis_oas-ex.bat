::!\bin\sh

:: Calculate phases from refined model for later comparison

sfall hklin %RNASE%\rnase25.mtz xyzin %RNASE%\rnase.pdb hklout %TEMPRES%\rnase_mod.mtz < %SCRIPTWIN%\oasis_oas1.dat

:: Run OASIS to get phases from Pt anomalous data

oasis hklin %TEMPRES%\rnase_mod.mtz hklout %TEMPRES%\rnase_phase.mtz < %SCRIPTWIN%\oasis_oas2.dat

dm hklin %TEMPRES%\rnase_phase.mtz hklout %TEMPRES%\rnase_dm.mtz < %SCRIPTWIN%\oasis_oas3.dat
