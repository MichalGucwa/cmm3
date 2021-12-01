::!\bin\sh
::!   Watertidy a) moves your water molecules so that they are in the
::!   same asymmetric unit as your molecule.
::!             b) endeavours to give a rational name to each water.
::!    The convention is: 
::!  For each protein chain assign a "first shell" water chain ID.
::!  Waters are renamed to have the residue NUMBER of the neighbouring O or N
::!  and the CHAIN ID assigned in the command file.
::!  ( " Neighbouring" is decided on the DISTANCE only of the water from the
::!      protein atom - the program DISTANG outputs a table.)
::!   An atom may occur more than once if it is near enough several O or N.
::!   The occupany for the nearest contact is equal to the input occupancy;
::!  all other occupancies are set o a very small value.
::   You may search for second andthird shell waters in a similar way.

::!    Run the distang-parts separately; the log-file is needed for a
::!  watertidy-run. 
::!
::!
::!    To sort waters: edit the water atoms from the end of the output pdb
::!   run the UNIX sort utility,  then put them back in some sensible order.
::!
::!   sort +4 -5 +5 -6 +2.1 -3 waterbit.pdb > waterbit_sort.pdb 
::!  will sort file first on chain id, then on residue number
::!              and finally on atom name
::!

:::::::::::::::::::::::::::::::::::::: Label Chains in toxd.pdb ::::::::::::::::::::::::::::
::			For watertidy (and others)

pdbset xyzin %TOXD%\toxd.pdb xyzout %TEMPRES%\toxd_chnid.pdb < %SCRIPTWIN%\water3shell1.dat

::!First H2O shell..
::!DISTANG - run distang first...
::!   Use pdbset.com to put chain labels in .....

distang XYZIN %TEMPRES%\toxd_chnid.pdb DISTOUT %TEMPRES%\watertidy-3shells.log1 < %SCRIPTWIN%\water3shell2.dat

::  Output file %TEMPRES%\toxd_chnid.pdb will contain protein and Sulphate
::  atoms followed by waters: Those close to protein will have been renamed;
::  remainder will still have original name and chain ID.

watertidy XYZIN %TEMPRES%\toxd_chnid.pdb XYZOUT %TEMPRES%\toxd_wtidy1.pdb DISTOUT %TEMPRES%\watertidy-3shells.log1 < %SCRIPTWIN%\water3shell3.dat

::!Second H2O shell..

::  Now check if some of the remaining waters are bonded to relabelled J and K; 
::  ie they are forming a second water shell.
::!Run DISTANG again.

distang XYZIN %TEMPRES%\toxd_wtidy1.pdb DISTOUT %TEMPRES%\watertidy-3shells.log2 < %SCRIPTWIN%\water3shell4.dat

:: Now do this:
::!  only interested now in contacts between H2Os in chains J and K 
::   and H2Os in chain W.
::   watertidy ignores all other contacts in log file.

watertidy XYZIN %TEMPRES%\toxd_wtidy1.pdb XYZOUT %TEMPRES%\toxd_wtidy2.pdb DISTOUT %TEMPRES%\watertidy-3shells.log2 < %SCRIPTWIN%\water3shell5.dat

::!Third H2O shell..
::  Now check if some of the remaining waters are bonded to relabelled L and M; 
::  ie they are forming a third water shell.
::!Run DISTANG again.

distang XYZIN %TEMPRES%\toxd_wtidy2.pdb DISTOUT %TEMPRES%\watertidy-3shells.log3 < %SCRIPTWIN%\water3shell6.dat

:: Now do this:

watertidy XYZIN %TEMPRES%\toxd_wtidy2.pdb XYZOUT %TEMPRES%\toxd_wtidy3.pdb DISTOUT %TEMPRES%\watertidy-3shells.log3 < %SCRIPTWIN%\water3shell7.dat
