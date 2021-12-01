::!\bin\sh -e

:: Test of differencing utilities: mtzdiff, mapdiff, pdbdiff

:: PDBDIFF
::=========================================
:: First make a new pdb file with different
:: coordinates

pdbset XYZIN %TOXD%\toxd.pdb XYZOUT %TEMPRES%\toxd_noise.pdb < %SCRIPTWIN%\differences1.dat

:: Examine the differences

pdbdiff %TOXD%\toxd.pdb %TEMPRES%\toxd_noise.pdb

:: MTZDIFF
::=========================================
:: Get structure factors from original coordinates

sfall XYZIN %TOXD%\toxd.pdb HKLIN %TOXD%\toxd.mtz HKLOUT %TEMPRES%\toxd_orig.mtz <  %SCRIPTWIN%\differences2.dat

:: Get structure factors from new coordinates

sfall XYZIN %TEMPRES%\toxd_noise.pdb HKLIN %TOXD%\toxd.mtz HKLOUT %TEMPRES%\toxd_noise.mtz < %SCRIPTWIN%\differences2.dat

:: Examine the differences

mtzdiff %TEMPRES%\toxd_orig.mtz %TEMPRES%\toxd_noise.mtz

:: MAPDIFF
::=========================================
:: Make a map from original coordinates

sfall XYZIN %TOXD%\toxd.pdb MAPOUT %TEMPRES%\toxd_orig.map < %SCRIPTWIN%\differences3.dat

:: Make a map from the new coordinates

sfall XYZIN %TEMPRES%\toxd_noise.pdb MAPOUT %TEMPRES%\toxd_noise.map < %SCRIPTWIN%\differences3.dat

:: Examine the differences

mapdiff %TEMPRES%\toxd_orig.map %TEMPRES%\toxd_noise.map

