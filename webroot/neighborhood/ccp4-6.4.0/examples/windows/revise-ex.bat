::!\bin\sh

:: Simple example using MAD data from tutorial
:: (This is probably not the best example for revise.)

na4tomtz HKLIN %DATA%\MAD_free.na4 HKLOUT %TEMPRES%\MAD_free.mtz

revise HKLIN %TEMPRES%\MAD_free.mtz HKLOUT %TEMPRES%\MAD_revised.mtz < %SCRIPTWIN%\revise.dat
