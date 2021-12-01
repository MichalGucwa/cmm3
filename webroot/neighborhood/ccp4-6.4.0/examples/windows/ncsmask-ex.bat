::!\bin\sh

:: awa
:: changes made on 98\06\30 to accomodate new formatt in toxd.pdb 

:: Make an averaging mask from toxd coordinates
:: (to illustrate program - no obvious use!)

:: select protein and sulphates only - don't want waters
:: contributing to mask

pdbset XYZIN %TOXD%\toxd.pdb XYZOUT %TEMPRES%\toxd_protein.pdb < %SCRIPTWIN%\ncsmask1.dat
::

:: Now make mask.
:: Mask will be in P1 unless keyword SYMM given.

ncsmask xyzin %TEMPRES%\toxd_protein.pdb mskout %TEMPRES%\junk.msk < %SCRIPTWIN%\ncsmask2.dat
