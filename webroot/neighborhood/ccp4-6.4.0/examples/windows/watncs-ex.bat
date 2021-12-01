::!\bin\sh
:: make PDB file of waters only

pdbset xyzin %RNASE%\rnase.pdb xyzout %TEMPRES%\rnase_wat.pdb < %SCRIPTWIN%\watncs1.dat

:: RELATE keyword gives rotation matrix (transpose of that output
:: by LSQKAB) and translation (in A) of NCS operation relating
:: two chains of rnase

watncs < %SCRIPTWIN%\watncs2.dat


