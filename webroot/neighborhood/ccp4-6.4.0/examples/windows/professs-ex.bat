::!/bin/sh

:: An example of a protein with 6 chains in the asymmetric unit. The 6 chains
:: are arranged into 3 dimers composed of chains A and B, C and F, and D and E. 
:: The input PDB file contains the SD atoms of Met residues only, to mimic a 
:: search using Se heavy atoms.

:: This example will run fine with the default program parameters. The program
:: finds 3 2-folds relating A to B (Polar 30.03761 -57.17715 179.9996), 
:: C to E (Polar 70.44804 151.8384 179.9996), and D to F (Polar 45.24121 
:: 70.64690 179.9996). These are marked as "Loop 2". There are also several
:: cases of "Loop 0" where the operator only acts one way, i.e. improper NCS.

professs xyzin %DATA%/1fse_sd_only.pdb < %SCRIPTWIN%\end.dat

