::!\bin\sh
::   Program to change coordinate formats.
::   PDBSET does some of these functions.
::   Takes PDB to fractional - often useful for heavy atom coordinates.
::    Adds CRYSTAL and SCALEi cards for various NCODEs to PDB.
::    SHELX to PDB - XPLOR to\from PDB etc....

::
::  Add CRYSTL and SCALEi cards to a PDB filewhere they are missing.
::

coordconv XYZOUT %TEMPRES%\toxd_orth1.pdb XYZIN %TOXD%\toxd.pdb < %SCRIPTWIN%\coordconv1.dat

::
::  Output fractional coordinates.
::

coordconv XYZOUT %TEMPRES%\toxd.frc XYZIN %TOXD%\toxd.pdb < %SCRIPTWIN%\coordconv2.dat

::
::

coordconv XYZIN %TEMPRES%\toxd.frc XYZOUT %TEMPRES%\toxd.pdb  < %SCRIPTWIN%\coordconv3.dat

::
coordconv XYZIN %TEMPRES%\toxd.frc XYZOUT %TEMPRES%\toxd-coord.xpl < %SCRIPTWIN%\coordconv4.dat 


