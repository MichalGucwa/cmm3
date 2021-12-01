::!/bin/sh

:: This is an example using TOXD.
:: The h-bonds are calculated for the sulphate molecules and waters residues 
:: 60 - 123.
:: The first line gives the maximum energy of a listed h-bond.
:: The second line should be 'INTER' if you wish only inter-subunit h-bonds.

hbond XYZIN %TOXD%\toxd.pdb < %SCRIPTWIN%\hbond.dat