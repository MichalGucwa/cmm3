::!\bin\sh
:: 
::   SCALEPACK2MTZ
::
::  h k l I+ SigI+ I- SigI-   were extracted from aucn.na4
::  (acentric data only), and put into scalepack format. 
::  This is simply to illustrate the procedure for getting 
::  scalepack data into CCP4. I don't really know if it
::  is a good example.
::
::  (You can use the same procedure whether or not you have 
::  anomalous data.)

scalepack2mtz hklin %DATA%\aucn.sca hklout %TEMPRES%\junk1.mtz < %SCRIPTWIN%\scalepack2mtz1.dat

:: convert Is to Fs and Ds.

truncate hklin %TEMPRES%\junk1.mtz hklout %TEMPRES%\junk2.mtz < %SCRIPTWIN%\scalepack2mtz2.dat

:: get correct sort order and asymmetric unit

cad hklin1 %TEMPRES%\junk2.mtz hklout %TEMPRES%\aucn_trn.mtz < %SCRIPTWIN%\scalepack2mtz3.dat
