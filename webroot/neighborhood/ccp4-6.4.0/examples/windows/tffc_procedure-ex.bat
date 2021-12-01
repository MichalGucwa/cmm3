::!\bin\sh
::  The procedure
::---> pdbset
::---> sfall
::---> cad
::---> tffc
::  Test of translation function procedure
::   NB: a translation solution here will be 
:: either 0.0 0.0 0.0
::   or   0.5 0.0 0.0
::   or   0.5 0.5 0.0
::   or   0.5 0.0 0.5
::   or   0.5 0.5 0.5
::   or   0.0 0.5 0.0
::   or   0.0 0.5 0.5
::   or   0.0 0.0 0.5
::   since we are "searching" with the actual coordinates

pdbset XYZIN %TOXD%\toxd_mod_p1.pdb XYZOUT %TEMPRES%\toxd_model_afterrotation.pdb < %SCRIPTWIN%\tffc_proc1.dat

sfall HKLOUT %TEMPRES%\toxd_p1.mtz XYZIN %TEMPRES%\toxd_model_afterrotation.pdb < %SCRIPTWIN%\tffc_proc2.dat

cad HKLIN1 %TOXD%\toxd.mtz HKLIN2 %TEMPRES%\toxd_p1.mtz HKLOUT %TEMPRES%\toxd_cad.mtz < %SCRIPTWIN%\tffc_proc3.dat

tffc HKLIN %TEMPRES%\toxd_cad.mtz HKLOUT %TEMPRES%\toxd_tffc.mtz < %SCRIPTWIN\%tffc_proc4.dat

::
:: ********************************************************************
:: *                                                 16\5\91          *
:: *   Run FFT  in Space group 1
:: *   This is NOT using your real h k l
:: *   Resolution limits are artificial; needs to be twice data 
:: *   resolution usually.
:: *   RESMAX = CELL(1)\"hmax" ( = CELL(2)\"kmax" = CELL(3)\"lmax")
:: *   Grid has to be at least 2*"hmax" +1 , etc
:: *   TFFC tells you the values of "hmax" etc
:: *   Output map should have a single peak giving translation vector.
:: *   Asymmetric unit is from one crystal origin to the next (same as RSEARCH)
:: *   But do 0-1 , 0-1 0-1 if you feel safer.... and check you have
:: *   duplicate solutions.
:: ********************************************************************

fft  HKLIN %TEMPRES%\toxd_tffc.mtz MAPOUT %TEMPRES%\tffc.map < %SCRIPTWIN%\tffc_proc5.dat

:: stats on the map:

mapsig mapin %TEMPRES%\tffc mapin2 %TEMPRES%\tffc peak_list %TEMPRES%\tf.peaks <%SCRIPTWIN%\end.dat
