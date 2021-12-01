::!\bin\sh

::  Read in coordinates to calculate structure factors. 
sfall	HKLIN %TOXD%\toxd.mtz HKLOUT %TEMPRES%\toxd_sf.mtz XYZIN %TOXD%\toxd.pdb XYZOUT  %TEMPRES%\junk.pdb < %SCRIPTWIN%\sfcalc1.dat

::   Alternative to show it works 
::  Calculate map from atom coordinates
::  and then generate structure factors from map

sfall	XYZIN %TOXD%\toxd.pdb MAPOUT %TEMPRES%\toxd_fc.map < %SCRIPTWIN%\sfcalc2.dat

::  Read in map to calculate structure factors. 
sfall	HKLIN %TOXD%\toxd.mtz HKLOUT %TEMPRES%\toxd_sf.mtz MAPIN %TEMPRES%\toxd_fc.map < %SCRIPTWIN%\sfcalc3.dat

::
