::!\bin\sh
::  Tabulates differences between 2 or 3 sets of coordinates, 
::   against atom type and B value and residue number.
:: COMPARISON OF COORDINATES - ON XYZIN1 XYZIN2  AND PROVISIONALLY XYZIN3.
::CARD 1 - TITLE
::CARD 2 - NSETS - NUMBER OF CORD SETS FOR COMPARISON (2 OR 3.)
::CARD 3 - DELXYZ DELB FOR MONITORING
::  RMSTAB is written out - useful for SQUID
::  A temporary file called TMPOUT is written.

IF NOT EXIST %TEMPRES%\rnase_out.pdb (echo '! run refmac5_tls.exam first' 1>&2 && GOTO :EOF)

compar XYZIN1 %RNASE%\rnase.pdb XYZIN2 %TEMPRES%\rnase_out.pdb RMSTAB %TEMPRES%\rnase.rms < %SCRIPTWIN%\compar.dat

