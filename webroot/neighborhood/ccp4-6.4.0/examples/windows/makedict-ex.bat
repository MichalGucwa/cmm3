::!\bin\csh -fe
::
:: This file contains two examples for using MAKEDICT to
:: generate PROTIN-style dictionary entries using coordinates
:: from pdb files.
::
:: Example 1: a simple example using a SUL residue cut
::            out of toxd.pdb
::
:: There are no planar groups, chiral centres etc.
::

makedict XYZIN %DATA%\toxd_sul.pdb DICT %TEMPRES%\toxd_sul.dict < %SCRIPTWIN%\makedict1.dat

::
:: Example 2: a slightly more complicated example using
::            the first ASP residue cut from rnase.pdb
::
:: First prepare a pdb file containing just the residue of
:: interest:

find "ASP A   1" %RNASE%\rnase.pdb > %TEMPRES%\rnase1.tmp

pdbset XYZIN %TEMPRES%\rnase1.tmp XYZOUT %TEMPRES%\rnase_asp.pdb < %SCRIPTWIN%\makedict2.dat

del %TEMPRES%\rnase1.tmp

:: Make the dictionary entry
:: Here we define a planar group and a chiral group

makedict XYZIN %TEMPRES%\rnase_asp.pdb DICT %TEMPRES%\rnase_asp.dict < %SCRIPTWIN%\makedict3.dat

:: See the MAKEDICT documentation for a description of how to
:: incorporate the resulting files into the dictionary.
::
