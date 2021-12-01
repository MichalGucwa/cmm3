::!\bin\sh
:: A simple Procedure  for finding water peaks. They can be compared with
:: the ones from toxd.pdb

::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:: Remove the original waters from toxd
::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::

pdbset XYZIN %TOXD%\toxd.pdb XYZOUT %TEMPRES%\temp1.pdb < %SCRIPTWIN%\watpeak1.dat

::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:: Calculate sfs for final coordinates -
::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::

sfall HKLIN %TOXD%\toxd.mtz HKLOUT %TEMPRES%\toxd.mtz XYZIN %TEMPRES%\temp1.pdb < %SCRIPTWIN%\watpeak2.dat

::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
::  Scale the Fc's to the Fo's
::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::

rstats hklin %TEMPRES%\toxd.mtz hklout %TEMPRES%\toxd_sc.mtz < %SCRIPTWIN%\watpeak3.dat

::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:: Fo-Fc map from final coordintes.  
::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::

fft HKLIN %TEMPRES%\toxd_sc.mtz MAPOUT %TEMPRES%\toxd_fo-fc.map < %SCRIPTWIN%\watpeak4.dat

::  run mapmask to cover molecule

mapmask XYZIN %TEMPRES%\temp1.pdb MAPIN  %TEMPRES%\toxd_fo-fc.map MAPOUT  %TEMPRES%\toxd_fo-fc.ext < %SCRIPTWIN%\watpeak5.dat

::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
::  Some peaks may appear twice since map has been extended.
::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::

peakmax XYZOUT %TEMPRES%\toxd_peaks.pdb MAPIN  %TEMPRES%\toxd_fo-fc.ext < %SCRIPTWIN%\watpeak6.dat

::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:: run atpeak to check distances within 3.6A
::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::

watpeak PEAKS %TEMPRES%\toxd_peaks.pdb XYZIN %TEMPRES%\temp1.pdb xyzout %TEMPRES%\toxd_waters.pdb < %SCRIPTWIN%\watpeak7.dat