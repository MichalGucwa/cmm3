::!\bin\sh

:: 1) Read in coordinates to calculate structure factors. 
::  Use sf_calc to produce %TEMPRES%\toxd_sf1.mtz
:: 2) Read in coordinates to calculate solvent density map.
::  Read in map to calculate "solvent" structure factors
::  in %TEMPRES%\toxd_sf_solv
:: 3) Use icoefl to scale SFs and solvent transform together.
::  No guarantee this will work sensibly; I dont know what to expect..
::  (in fact, the converged parameters don't look v. sensible,
::  but you get the idea).

::  Read in coordinates to calculate structure factors. 

sfall	HKLIN %TOXD%\toxd HKLOUT %TEMPRES%\toxd_sf1 XYZIN %TOXD%\toxd.pdb < %SCRIPTWIN%\icoefl1.dat

::  Calculate solvent map from atom coordinates
::  and then generate structure factors from map
::

sfall	XYZIN %TOXD%\toxd.pdb MAPOUT %TEMPRES%\toxd_solv < %SCRIPTWIN%\icoefl2.dat

::  Read in map to calculate "solvent" structure factors. 
sfall HKLIN  %TEMPRES%\toxd_sf1 HKLOUT %TEMPRES%\toxd_sf_solv MAPIN %TEMPRES%\toxd_solv < %SCRIPTWIN%\icoefl3.dat

::  Scale 

icoefl HKLIN %TEMPRES%\toxd_sf_solv.mtz hklout %TEMPRES%\toxd_sf2.mtz < %SCRIPTWIN%\icoefl4.dat

