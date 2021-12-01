::!\bin\sh

:: Fairly artificial example, as a test.
:: Convert structure factors to intensities for input to SORTMTZ\SCALA,
:: perhaps as a reference dataset.

combat HKLIN %TOXD%\toxd.mtz HKLOUT %TEMPRES%\toxd_multi.mtz < %SCRIPTWIN%\combat.dat

::
