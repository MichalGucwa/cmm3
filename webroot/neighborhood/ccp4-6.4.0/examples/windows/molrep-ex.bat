::!\bin\sh


:: Example of MOLREP to find 2 chains in asu for rnase,
:: using good poly-ALA search model.
:: Solution agrees with refined model in rnase.pdb to within
:: some crystal symmetry operations.

molrep HKLIN %RNASE%\rnase18.mtz MODEL %RNASE%\mr_mod.pdb < %SCRIPTWIN%\molrep.dat
Del molrep.doc