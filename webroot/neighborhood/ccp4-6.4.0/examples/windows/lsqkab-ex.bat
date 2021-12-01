::!\bin\sh 

:: Use pdbcur to rotate\translate rnase model by arbitrary amounts.
:: Then use lsqkab to recover original coordinates by a fitting.
:: %TEMPRES%\rnase_fitted.pdb should correspond to the original %RNASE%\rnase.pdb

pdbcur xyzin %RNASE%\rnase.pdb xyzout %TEMPRES%\rnase_transf.pdb < %SCRIPTWIN%\lsqkab1.dat

lsqkab XYZINM %TEMPRES%\rnase_transf.pdb XYZINF %RNASE%\rnase.pdb XYZOUT %TEMPRES%\rnase_fitted.pdb < %SCRIPTWIN%\lsqkab2.dat

::  lsqkab being used to apply a rotation & translation
::  Alternative: use PDBSET

lsqkab XYZIN2 %TOXD%\toxd.pdb XYZOUT %TEMPRES%\toxd_rot_trans.pdb	< %SCRIPTWIN%\lsqkab3.dat

:: Obtain NCS rotation\translation relating chain A to chain B
:: First make a temporary copy of the original file

copy %RNASE%\rnase.pdb %TEMPRES%\dolldoll.pdb

lsqkab xyzin2 %RNASE%\rnase.pdb xyzin1 %TEMPRES%\dolldoll.pdb RMSTAB %TEMPRES%\rnase_rms.tab  < %SCRIPTWIN%\lsqkab4.dat

:: Remove the temporary copy
del %TEMPRES%\dolldoll.pdb
