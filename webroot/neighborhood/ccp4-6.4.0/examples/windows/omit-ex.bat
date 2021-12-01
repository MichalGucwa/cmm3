::!/bin/sh

IF NOT EXIST %TEMPRES%\toxd_sf.mtz (echo '! run sf_calc first' 1>&2 && GOTO :EOF)

:: Minimal example

omit hklin %TEMPRES%\toxd_sf.mtz mapout %TEMPRES%\output_1.map < %SCRIPTWIN%\omit1.dat

:: Add title, set map grid, and do histogram mapping of omit
:: map to starting map.

omit hklin %TEMPRES%\toxd_sf.mtz mapout %TEMPRES%\output_2.map < %SCRIPTWIN%\omit2.dat

