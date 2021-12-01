::!\bin\sh
::
::  Calculations leading up to map correlations.
:: Need two maps, and if you want to tabulate the results 
:: residue by residue, a third "map" output by sfall which 
:: flags each grid point with the residue which makes the 
:: largest contribution to it.
::  Warning. All grids MUST BE THE SAME!!
::  It is probably sensible if you want results tabulated according
:: to residue to make this a fine grid, the sfall one should be OK.
::  Here is a set of command files to check the map correlation of 
:: a structure after refinement to the MIR map,
::  and to work out real space R factors.
::  For map correlation we use 1) The MIR map ( should be dm'ed map)
::                             2) An "FC" map 
::               and           3) the sfall RESMOD map.

::  For Real space R factors we also need the FO map phased by the PHIcalc.
::  Here we are getting correlations between final coordinates, and initial ones

IF NOT EXIST %TEMPRES%\toxd_phase_mir.mtz (echo "! run the mlphare procedure first" 1>&2 && GOTO :EOF)

::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
::  Generate atom map with flags for each residue from FINAL coordinates
::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::

sfall xyzin %TOXD%\toxd.pdb mapout %TEMPRES%\last.map < %SCRIPTWIN%\mapcorpro1.dat 

::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
::  Calculate sfs for FINAL coordinates - 
::   Simlest to append output FC and PHIC to MIR mtz file which contains
::  MIR phase information, also useful for different map generation.
::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::

sfall xyzin %TOXD%\toxd.pdb hklin %TEMPRES%\toxd_phase_mir.mtz  hklout %TEMPRES%\toxd_phase_mir_sflast.mtz < %SCRIPTWIN%\mapcorpro2.dat 

::
:: Calculate maps:
::  For real space R factor I need Fo and Fc maps..
:: Fo map phased on original coordinates.
::
::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:: Fo map from final coordinates.  (used for Real Space R factor)
::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::

fft mapout %TEMPRES%\folast.map hklin %TEMPRES%\toxd_phase_mir_sflast.mtz < %SCRIPTWIN%\mapcorpro3.dat

::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:: Fc map from final coordinates.
::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::

fft mapout %TEMPRES%\fclast.map hklin %TEMPRES%\toxd_phase_mir_sflast.mtz < %SCRIPTWIN%\mapcorpro4.dat

::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
::  mir map
::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::

fft mapout %TEMPRES%\fomir.map hklin %TEMPRES%\toxd_phase_mir_sflast.mtz < %SCRIPTWIN%\mapcorpro5.dat

::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
::  Correlation residue by residue of final coordinates with mir map
::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::

overlapmap mapin1 %TEMPRES%\fomir.map mapin2 %TEMPRES%\fclast.map mapin3 %TEMPRES%\last.map < %SCRIPTWIN%\mapcorpro6.dat

::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
::  Real space R factor residue by residue of final coordinates 
::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::

overlapmap mapin1 %TEMPRES%\folast.map mapin2 %TEMPRES%\fclast.map mapin3 %TEMPRES%\last.map < %SCRIPTWIN%\mapcorpro7.dat
