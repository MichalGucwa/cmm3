::!\bin\sh 
::  Take MTZ to ASCII format suitable for transfer betwen machines.
::  Conversion back done by na4tomtz
::::::::::::::::::::com file to run mtz2na4::::::::::::::::::::::::

mtztona4 HKLIN  %TOXD%\toxd.mtz  HKLOUT %TEMPRES%\toxd.card 

::::::::::::::::::::com file to run na4tomtz::::::::::::::::::::::::

na4tomtz HKLIN  %TEMPRES%\toxd.card  HKLOUT %TEMPRES%\toxd.mtz 
