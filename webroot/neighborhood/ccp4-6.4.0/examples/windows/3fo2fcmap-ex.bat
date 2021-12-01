
:: calculate Fc

sfall xyzin %TOXD%\toxd.pdb hklin %TEMPRES%\toxd_phase_mir hklout %TEMPRES%\3fo2fc_tox < %SCRIPTWIN%\3fo2fcmap1.dat

:: scale Fo, Fc
rstats hklin %TEMPRES%\3fo2fc_tox hklout %TEMPRES%\tox_fofc-rs < %SCRIPTWIN%\3fo2fcmap2.dat

del %TEMPRES%\3fo2fc_tox.mtz

:: make the map
fft hklin %TEMPRES%\tox_fofc-rs mapout %TEMPRES%\3fo2fc < %SCRIPTWIN%\3fo2fcmap3.dat

del %TEMPRES%\tox_fofc-rs.mtz

:: find the peaks
peakmax mapin %TEMPRES%\3fo2fc PEAKS %TEMPRES%\3fo2fc.peaks < %SCRIPTWIN%\3fo2fcmap4.dat
