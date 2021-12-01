::!\bin\sh

::
:: Procedure  for finding water peaks. 
:: An atom map generated with SFALL is used to mask out the protein regions in
:: both an fo-fc and 2fo-fc map.  These solvent maps are then averaged and 
:: searched for peaks.  
::
:: fofcmap script does the same thing but only uses fo-fc map
::

::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:: Generate atom map for final coordinates
::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::

sfall MAPOUT %TEMPRES%\toxd_fc.map XYZIN %TOXD%\toxd.pdb < %SCRIPTWIN%\waterpeaks1.dat 

::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:: Calculate sfs for final coordinates -
::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::

sfall HKLIN %TOXD%\toxd.mtz HKLOUT %TEMPRES%\toxd.mtz  XYZIN %TOXD%\toxd.pdb < %SCRIPTWIN%\waterpeaks2.dat

::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:: Fo-Fc map from final coordintes.  
::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::

fft HKLIN %TEMPRES%\toxd.mtz  MAPOUT %TEMPRES%\toxd_fo-fc.map  < %SCRIPTWIN%\waterpeaks3.dat

::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:: 2Fo -fc map from final coordintes.  
::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::

fft HKLIN %TEMPRES%\toxd.mtz  MAPOUT %TEMPRES%\toxd_2fo-fc.map  < %SCRIPTWIN%\waterpeaks4.dat

::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:: exclude points from 2fo-fc map which occur in fcalc map
::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::

overlapmap MAPIN1 %TEMPRES%\toxd_fc.map  MAPIN2 %TEMPRES%\toxd_2fo-fc.map  MAPOUT %TEMPRES%\toxd_2fo-fc_masked.map  < %SCRIPTWIN%\waterpeaks5.dat

::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:: exclude points from fo-fc map which occur in fcalc map
::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::

overlapmap MAPIN1 %TEMPRES%\toxd_fc.map  MAPIN2 %TEMPRES%\toxd_fo-fc.map  MAPOUT %TEMPRES%\toxd_fo-fc_masked.map  < %SCRIPTWIN%\waterpeaks5.dat

::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:: average 2 solvent maps now
::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::

overlapmap MAPIN1  %TEMPRES%\toxd_fo-fc_masked.map MAPIN2  %TEMPRES%\toxd_2fo-fc_masked.map MAPOUT  %TEMPRES%\toxd_av_masked.map < %SCRIPTWIN%\waterpeaks6.dat

::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:: run peakmax with electron density level 0.15  - look at 2fo-fc, fo-fc 
::                                                 to get sensible level
::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
::  run mapmask to cover molecule

mapmask XYZIN %TOXD%\toxd.pdb MAPIN  %TEMPRES%\toxd_av_masked.map MAPOUT  %TEMPRES%\toxd_av_masked.ext < %SCRIPTWIN%\waterpeaks7.dat

::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
::  Some peaks may appear twice since map has been extended.
::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::

peakmax XYZOUT %TEMPRES%\toxd_peaks.pdb MAPIN  %TEMPRES%\toxd_av_masked.ext < %SCRIPTWIN%\waterpeaks8.dat

::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:: run atpeak to check distances within 3.6A
::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::

watpeak PEAKS %TEMPRES%\toxd_peaks.pdb XYZIN %TOXD%\toxd.pdb xyzout %TEMPRES%\toxd_waters.pdb < %SCRIPTWIN%\waterpeaks9.dat
