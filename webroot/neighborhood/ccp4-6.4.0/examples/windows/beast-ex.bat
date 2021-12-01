::!\bin\sh
::
:: Rotation search (full) for toxd using 1BIK.pdb
:: This is a quick test to see if the program's working properly.
:: It happens to find the right orientation by luck, but the sampling
:: of orientations is much too coarse.  A sampling interval of 3.6 is
:: my normal default at the moment.  Eventually, the program will supply
:: a sensible default based on size, resolution and model quality.
:: SEARCH mol1 ROTATE FULL 
::

beast HKLIN %TOXD%\toxd.mtz < %SCRIPTWIN%\beast1.dat

::******************************************************************************
:: Rotation search (limited) of toxd using the solution toxd.pdb file (!)
:: Search restricted to around the origin because using a model pre-aligned
::   to the solution
:: SEARCH mol1 ROTATE AROUND 0.0 0.0 0.0 3.0

beast HKLIN %TOXD%\toxd.mtz < %SCRIPTWIN%\beast2.dat

::******************************************************************************
:: Rotation search of toxd data using an ensemble of 2 models
:: The two models are 1BIK.pdb and the B chain of 1D0D.pdb
:: The models must be aligned to each other:
::   here 1BIK has been aligned to the B chain of 1D0D.pdb
:: SEARCH mol1 ROTATE FULL 3.6

beast HKLIN %TOXD%\toxd.mtz < %SCRIPTWIN%\beast3.dat

::******************************************************************************
:: Rotation search (refinement of previous rotation search solutions)

beast HKLIN %TOXD%\toxd.mtz < %SCRIPTWIN%\beast4.dat

::******************************************************************************
:: Translation search (full) around one rotation search solution  
:: Normally should use a sampling of dmin\4 or finer.
::            TRANSLATE REGION 0.0 0.5 0.0 0.5 0.0 0.5 0.5

beast HKLIN %TOXD%\toxd.mtz < %SCRIPTWIN%\beast5.dat

::******************************************************************************
:: Translation search (full) around three rotation search solutions

beast HKLIN %TOXD%\toxd.mtz < %SCRIPTWIN%\beast6.dat

::******************************************************************************
:: Final refinement search (6D) around a specific rotation and translation

beast HKLIN %TOXD%\toxd.mtz < %SCRIPTWIN%\beast7.dat

