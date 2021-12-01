
::!\bin\sh
::   First calculate structure factors for model coordinates in P1 cell.
:: Dont forget to change the CRYSTL and SCALEi cards at the head 
:: of the PDB file to those appropriate for the "P1 " model cell. 
:: eg: for a cell 50*50*50 you need this.
::CRYST1   50.00    50.00    50.00   90.00  90.00   90.00
::SCALE1      0.020000  0.000000  0.000000        0.00000
::SCALE2      0.000000  0.020000  0.000000        0.00000
::SCALE3      0.000000  0.000000  0.020000        0.00000

::  toxd_mod_p1.pdb obtained from toxd.pdb by
::  1) changing CRYSTL and SCALEi cards
::  2) removing water molecules.
:: this has been done with the supplied version

::  Read in coordinates to calculate structure factors. 
sfall  HKLOUT %TEMPRES%\toxd_mod_p1 XYZIN %TOXD%\toxd_mod_p1.pdb < %SCRIPTWIN%\almn1.dat


::  Generate E values for Observed F's ( Ian Tickle says so)
::

ecalc hklin %TOXD%\toxd hklout %TEMPRES%\toxd_e.mtz < %SCRIPTWIN%\almn2.dat

::
::  Generate E values for Calculated F's
::
ecalc hklin %TEMPRES%\toxd_mod_p1 hklout %TEMPRES%\toxd_mod_p1_e < %SCRIPTWIN%\almn3.dat


::
:: Then run ALMN
::
almn HKLIN %TEMPRES%\toxd_e HKLIN2 %TEMPRES%\toxd_mod_p1_e MAPOUT %TEMPRES%\almn.map < %SCRIPTWIN%\almn4.dat
