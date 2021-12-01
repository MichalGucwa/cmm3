::!\bin\sh 
::  Alternative program of Phils.
::  Alternative inputs - PDB,fractional or phare_ml
:: Examples
:: 1)   Input fractional sites 
::   Free format:   Occup   x y z b
::
:: 2)Input PHARE fractional sites 
::ATOM   AU    0.177  0.104 -0.114  9.92
::ATOM   AU    0.218  0.138 -0.105  4.88
::ATOM   HG    0.180  0.294  0.089 13.41
::ATOM   I     0.491  0.370  0.487  8.40
::
:: 3) PDB - usual sort of stuff CRYSTAL\SCALEi coordinates.
::

havecs XYZIN %DATA%\sites.frc XYZOUT %TEMPRES%\sites.pdb	UVWOUT %TEMPRES%\sitesuvw.pdb	< %SCRIPTWIN%\havecs1.dat 

::
havecs XYZIN %TEMPRES%\sites.pdb UVWOUT %TEMPRES%\sitesuvw.pdb XYZOUT %TEMPRES%\more_sites.pdb < %SCRIPTWIN%\havecs2.dat 
