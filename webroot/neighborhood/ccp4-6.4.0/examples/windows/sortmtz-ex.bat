::!\bin\sh
:: A complicated sortmtz example to test dataset handling.
:: WARNING: this does not represent a real-life program sequence!
:: There is a simpler example of sortmtz in scala.exam

na4tomtz hklin %DATA%\aucn.na4 hklout %TEMPRES%\aucn.mtz

:: Create 3 files with different datasets. The datasets have
:: different cell dimensions as well as different wavelengths and 
:: so represent different crystals.

rebatch HKLIN %TEMPRES%\aucn.mtz HKLOUT %TEMPRES%\aucn_1.mtz < %SCRIPTWIN%\sortmtz1.dat

rebatch HKLIN %TEMPRES%\aucn.mtz HKLOUT %TEMPRES%\aucn_2.mtz < %SCRIPTWIN%\sortmtz2.dat

rebatch HKLIN %TEMPRES%\aucn.mtz HKLOUT %TEMPRES%\aucn_3.mtz < %SCRIPTWIN%\sortmtz3.dat

:: Now sort and merge the 3 files.

sortmtz HKLOUT %TEMPRES%\aucn_sortmtz.mtz < %SCRIPTWIN%\sortmtz4.dat

:: Check the output. Note that the batch headers were not changed by
:: the rebatch runs, but the main header should be correct.

mtzdump HKLIN %TEMPRES%\aucn_sortmtz.mtz < %SCRIPTWIN%\sortmtz5.dat

