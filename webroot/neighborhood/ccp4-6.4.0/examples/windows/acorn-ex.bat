::!\bin\sh -e

:: Run ACORN on deuterolysin data using single zinc atom
:: as a starting point

:: Step 1: Generate E's from F's
:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::: 

ecalc HKLIN %DATA%\deuterolysin.mtz HKLOUT %TEMPRES%\deuterolysin_e.mtz < %SCRIPTWIN%\acorn1.dat

:: Step 2: Run Acorn
:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::: 

acorn HKLIN %TEMPRES%\deuterolysin_e.mtz XYZIN %DATA%\deuterolysin_zn.pdb HKLOUT %TEMPRES%\deuterolysin_a.mtz < %SCRIPTWIN%\acorn2.dat
