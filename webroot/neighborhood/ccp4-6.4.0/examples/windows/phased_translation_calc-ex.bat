::!\bin\sh  
::

::!   phased translation function calculation
::
::!  Step 1.  Calculate isomorphous phaseds 
::             or get phases any other way - ie partial structure
::!::
::!  Step 2.  CAD will extend data to generate a file containing 
::!           h k l s   Fobs SIGFobs Phi FOM for 
::!           all h k l in P1 hemisphere.
::!::
::!  Step 3.  Calculate structure factors in P1 from model coordinates
::!           in cell with cell dimensions of the new structure;
::!           coordinates rotated to "correct" orientation...
::
::!  Cad again to combine these two files.
::!  Step 4.  CAD will add to the file containing 
::!           h k l s   Fobs Phiiso  Fcalc Phi calc for 
::!           all h k l in hemisphere the FC PHIC from step 2.
::!  You have to run this in spacegroup 1.
::
::!::
::!  Step 5.  the FFT can use these to generate a phased Translation
::!           function.
::!::

IF NOT EXIST %TEMPRES%\toxd_phase_mir.mtz  (echo "! run the mlphare procedure first" 1>&2 && GOTO :EOF)

::   Step 1 - use isomorphous phaseds.

::   Step 2 - use CAD
::!    Extend phasedd MTZ file from P212121 to P1

cad HKLIN1 %TEMPRES%\toxd_phase_mir.mtz HKLOUT %TEMPRES%\expanded.mtz  < %SCRIPTWIN%\phased_trans_calc1.dat

::   Step 3 - use LSQKAB to rotate coordinates to new orientation.
::
::  run lsqkab first to rotate coordinates to orientation given
::     by rotation function (almn, amore)
:: Remember to change the CRYSTL and SCALEi cards in the PDB file to
::  those appropriate for the new cell.
:: ********************************************************************

lsqkab WORKCD %TOXD%\toxd.pdb LSQOP %TEMPRES%\toxd_rot.pdb	< %SCRIPTWIN%\phased_trans_calc2.dat 

:: 
::  Step 3a -calculate P1 sfs  for these coordinates.

sfall XYZIN %TEMPRES%\toxd_rot.pdb HKLOUT %TEMPRES%\toxd_rot.mtz < %SCRIPTWIN%\phased_trans_calc3.dat

::   Step 4 
::!  CAD
::!  Cad again to combine these two files. Work in P1
:: Include FC PHIC

cad hklin1 %TEMPRES%\toxd_rot.mtz hklin2 %TEMPRES%\expanded.mtz hklout %TEMPRES%\final.mtz < %SCRIPTWIN%\phased_trans_calc4.dat

::   Step 5 
::!  phasedd translation function for isomorphous phaseds set::
::

fft HKLIN %TEMPRES%\final.mtz MAPOUT %TEMPRES%\final.map < %SCRIPTWIN%\phased_trans_calc5.dat
