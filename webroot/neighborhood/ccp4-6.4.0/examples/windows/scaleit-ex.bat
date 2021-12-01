::!\bin\sh
::

::
::  SCALEIT:  derivative to native scaling
::
::  In this example, we estimate and refine a scale and 
::  isotropic temperature factor for each derivative. These
::  are then applied to the derivative data output to HKLOUT.

::  Here we scale all three sets of derivative data included
::  in toxd.mtz. If instead only one derivative is specified,
::  then a Normal Probability Analysis for both centric and
::  acentric data is performed in addition to the usual analysis.
::

scaleit HKLIN %TOXD%\toxd.mtz HKLOUT %TEMPRES%\toxd_sc.mtz < %SCRIPTWIN%\scaleit.dat


