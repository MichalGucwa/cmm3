::!\bin\sh
:: 1. Generate the contents of the unit cell using given symmetry.
::    Symmetry-generated chains are then renamed.

pdbcur xyzin %RNASE%\rnase.pdb xyzout %TEMPRES%\ucell.pdb < %SCRIPTWIN%\pdbcur1.dat

:: 2. Same again but using automatic chain naming.

pdbcur xyzin %RNASE%\rnase.pdb xyzout %TEMPRES%\ucell.pdb < %SCRIPTWIN%\pdbcur2.dat

:: 3. Declare and then apply two symmetry operators.

pdbcur xyzin %RNASE%\rnase.pdb xyzout %TEMPRES%\rnase1.pdb < %SCRIPTWIN%\pdbcur3.dat

