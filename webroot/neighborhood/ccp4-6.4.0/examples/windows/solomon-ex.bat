::!\bin\csh -f
::
::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
::
:: AVERAGING PROCEDURE USING SOLOMON
::
:: Script to run several cycles of density modification, in
:: this case with a flip value (solvmul) of -1.0. This 
:: corresponds to adding the inverted solvent density to 
:: the initial map. This is similar to adding negative noise
:: to an image in order to strengthen the signal\noise ratio.
::
:: The resolution of the map is extended from 3.0 to 2.7
:: The variable $res defines the resolution at which the
:: current refinement cycle is working. This outlines the 
:: general program order that is required but obviously the 
:: procedure will be different for other structures. Automatic 
:: refinement over a large number of cycles is not advisable, 
:: the increase in map quality is the most important factor.
::
:: Note that the 'final' map from each cycle is kept i.e. 
:: the ones calculated from the combined structure factors.
:: Along with the MTZ file that generated it and the solomon
:: log files are appended.
::
::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
::


IF NOT EXIST %TEMPRES%\toxd_phase_mir.mtz (echo '! run the mlphare procedure first' && GOTO :EOF)

IF EXIST %TEMPRES%\toxd_stats.log (del %TEMPRES%\toxd_stats.log)

IF EXIST %TEMPRES%\toxd_Solomon.log (del %TEMPRES%\toxd_Solomon.log)

::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
::  Calculate initial map with best phases and FOM weighted 
::  amplitudes.
::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::

fft HKLIN %TEMPRES%\toxd_phase_mir.mtz MAPOUT %TEMPRES%\toxd_cycle0.map < %SCRIPTWIN%\solomon1.dat  >%TEMPRES%\null

solomon-exa