::!\bin\sh 

:: Remember the order of reflections in the output file will be funny.
:: Use cad or sortmtz to fix it.

:: E.g. 1 
:: Re-index a merged file.

reindex HKLIN  %TOXD%\toxd_old HKLOUT %TEMPRES%\toxd_reind1 < %SCRIPTWIN%\reindex1.dat 

echo H K L | sortmtz HKLIN %TEMPRES%\toxd_reind1 HKLOUT %TEMPRES%\toxd_reind2

:: E.g. 2
:: Reduce an unmerged file to a different point group

na4tomtz hklin %DATA%\aucn.na4 hklout %TEMPRES%\aucn.mtz

reindex hklin %TEMPRES%\aucn.mtz hklout %TEMPRES%\aucn_reindex.mtz < %SCRIPTWIN%\reindex2.dat

