::! \bin\sh

:: Example for DM 1.8

:: solvent\histogram calculation with dm. Free indicator will be calculated 
:: for complete cross validation. Will terminate automatically

IF NOT EXIST %TEMPRES%\toxd_phase_mir.mtz ( echo "! run the mlphare.exam procedure first" 1>&2 && GOTO :EOF)

dm hklin %TEMPRES%\toxd_phase_mir hklout %TEMPRES%\toxd_dm solout %TEMPRES%\solvent.msk < %SCRIPTWIN%\dm1.dat

:: Calculate maps from density modified map.

fft hklin %TEMPRES%\toxd_dm MAPOUT %TEMPRES%\toxd_dm.map < %SCRIPTWIN%\dm2.dat

:: Plot map sections, better to look with O

npo mapin %TEMPRES%\toxd_dm.map xyzin1 %TOXD%\toxd.pdb plot %TEMPRES%\dm.plt < %SCRIPTWIN%\dm3.dat
