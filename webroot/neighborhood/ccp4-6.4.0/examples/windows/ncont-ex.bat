::!\bin\sh

:: 1. Find contacts between chain A and chain B:

ncont  xyzin %RNASE%\rnase.pdb < %SCRIPTWIN%\ncont1.dat

:: 2. Find contacts between carbons of chain A and whole chains B
::    of all same-cell symmetry mates:

ncont  xyzin %RNASE%\rnase.pdb < %SCRIPTWIN%\ncont2.dat

