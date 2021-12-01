::!\bin\sh

IF NOT EXIST %TEMPRES%\toxd_sf.mtz (echo '! run sf_calc first' 1>&2 && GOTO :EOF)

IF NOT EXIST %TEMPRES%\toxd_phase_mir.mtz (echo '! run the mlphare-ex procedure first' 1>&2 && GOTO :EOF)

:: Calculate m|Fo| - D|Fc| and 2m|Fo| - D|Fc| coefficients from
:: native structure factor amplitude and calculated structure
:: factor. These are similar to the coefficients output by REFMAC.
:: used to distinguish different runs in html logfile

sigmaa hklin %TEMPRES%\toxd_sf hklout %TEMPRES%\junk < %SCRIPTWIN%\sigmaa1.dat

::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
::         Set option COMBINE to combine phase information from
:: eg isomorphous  replacement with partial structure
::
::  Calculate structure factors.
::  File toxd_mir.mtz  can be generated using mlphare.sh

sfall HKLIN %TEMPRES%\toxd_phase_mir HKLOUT %TEMPRES%\toxd_sf_mir XYZIN %TOXD%\toxd.pdb < %SCRIPTWIN%\sigmaa2.dat

sigmaa HKLIN  %TEMPRES%\toxd_sf_mir hklout %TEMPRES%\junk < %SCRIPTWIN%\sigmaa3.dat
