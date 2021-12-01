::!\bin\sh

IF NOT EXIST %TEMPRES%\toxd_sf.mtz (echo '! run sf_calc first' 1>&2 && GOTO :EOF)

:: Changing the symmetry of a mtz file

mtzutils hklin1 %TOXD%\toxd.mtz  hklout %TEMPRES%\junk.mtz < %SCRIPTWIN%\mtzutils1.dat

:::::::::::::::::: 2nd Example ::::::::::::::::::::::::::

mtzutils hklin1 %TOXD%\toxd.mtz hklin2 %TEMPRES%\toxd_sf.mtz hklout %TEMPRES%\junk.mtz < %SCRIPTWIN%\mtzutils2.dat
