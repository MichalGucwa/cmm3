::! \bin\sh


IF NOT EXIST %TEMPRES%\toxd_aupatt.map (echo '! run patterson first' 1>&2 && GOTO :EOF)


:: Generate Patterson vectors from coordinates of Au sites.
:: XYZIN - atom coordinates in pdb format
:: MAPIN is used to define extent and symmetry of Patterson.
:: XYZOUT contains the vectors.

vectors mapin %TEMPRES%\toxd_aupatt.map xyzout %TEMPRES%\vectors1.pdb < %SCRIPTWIN%\vectors1.dat

:: same again but input from PDB file

coordconv XYZIN %DATA%\sites.frc XYZOUT %TEMPRES%\sites.pdb < %SCRIPTWIN%\vectors2.dat

vectors xyzin %TEMPRES%\sites.pdb mapin %TEMPRES%\toxd_aupatt.map xyzout %TEMPRES%\vectors2.pdb < %SCRIPTWIN%\vectors3.dat

:: as for first example, but for vectors in volume defined by keyword xyzlim
:: rather than defined by mapin

vectors  xyzout %TEMPRES%\vectors3.pdb < %SCRIPTWIN%\vectors4.dat

:: example where atoms are input from both xyzin and ATOM keyword lines

vectors xyzin %TEMPRES%\sites.pdb mapin %TEMPRES%\toxd_aupatt.map xyzout %TEMPRES%\vectors4.pdb < %SCRIPTWIN%\vectors5.dat

:: Now we compare these vectors with the Patterson map.

npo mapin %TEMPRES%\toxd_aupatt.map xyzin %TEMPRES%\vectors1.pdb plot %TEMPRES%\patt.plt < %SCRIPTWIN%\vectors6.dat


:: You can view the plot file with xplot84driver
 
