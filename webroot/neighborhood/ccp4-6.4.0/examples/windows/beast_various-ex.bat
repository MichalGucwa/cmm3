::!\bin\csh
::
:: Refine orientation and translation.
::
beast HKLIN %TOXD%\toxd.mtz <  %SCRIPTWIN%\beastvar1.dat

::
:: Rescore rotation function results from Molrep using 1BIK_on_1D0D_B.pdb.
::

beast HKLIN %TOXD%\toxd.mtz < %SCRIPTWIN%\beastvar2.dat

:: Rotation search (full) for toxd using an ensemble of two models.
:: The two models are 1BIK.pdb and the B chain of 1D0D.pdb
:: The models must be aligned to each other:
::   here 1BIK has been aligned to the B chain of 1D0D.pdb
::
:: This test job happens to find the right orientation by luck, but the 
:: sampling of orientations is much too coarse.  The program will provide
:: a sensible default based on size and resolution, which would be 5 degrees
:: in this case.
::

beast HKLIN %TOXD%\toxd.mtz < %SCRIPTWIN%\beastvar3.dat

:: Refine orientations.
:: The search radius is small compared to the very coarse search grid 
:: used in the full search, but appropriate for a normal search grid.
:: Orientations from a full search are unlikely to be in error by much
:: more than half the step size, so 2\3 of that step size would be an
:: appropriate radius for refining possible solutions.
::

beast HKLIN %TOXD%\toxd.mtz < %SCRIPTWIN%\beastvar4.dat

::
:: Translation search after orientation refinement.
::

beast HKLIN %TOXD%\toxd.mtz < %SCRIPTWIN%\beastvar5.dat
