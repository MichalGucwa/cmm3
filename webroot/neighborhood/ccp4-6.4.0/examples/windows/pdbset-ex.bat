::!\bin\sh
:: Run PDB file through PDBSET with no keywords.
:: PDBSET will tidy the format where possible.
:: In this case, the TER card is re-written according to full PDB specification.

pdbset XYZIN %TOXD%\toxd.pdb XYZOUT %TEMPRES%\toxd_tidy.pdb < %SCRIPTWIN%\end.dat

::::::::::::::::::::::::::::::::::::::  Take output from O into a form suitable for refinement

pdbset xyzin %TOXD%\toxd.pdb xyzout %TEMPRES%\toxd_junk.pdb < %SCRIPTWIN%\pdbset1.dat

::::::::::::::::::::::::::::::::::::::  Take output from Xplor into a form suitable for refinement

:: fr45: commented this example as the file toxd_xplor does not exists
::pdbset xyzin %TOXD%\toxd_xplor.pdb xyzout %TEMPRES%\junk.pdb < %SCRIPTWIN%\pdbset2.dat

:::::::::::::::::::::::::::::::::::::: Re-label chains in toxd.pdb ::::::::::::::::::::::::::::

:: First we give waters unique residue numbers

pdbset xyzin %TOXD%\toxd.pdb xyzout %TEMPRES%\toxd_relabel1.pdb < %SCRIPTWIN%\pdbset3.dat

:: Second we do several chain name edits. Net effect should be zero in this example!

pdbset xyzin %TEMPRES%\toxd_relabel1.pdb xyzout %TEMPRES%\toxd_relabel2.pdb < %SCRIPTWIN%\pdbset4.dat

:: Reset B values to a given range

pdbset xyzin %TOXD%\toxd.pdb xyzout %TEMPRES%\toxd_bfac.pdb < %SCRIPTWIN%\pdbset5.dat

:::::::::::::::::::::::::::::::::::::::::::::::: Expand dimer to tetramer, rename chains, transform
::  Make tetramer from dimer

::pdbset xyzin ecrproducts268.pdb xyzout ecrprodpqrtet.pdb < %SCRIPTWIN%\pdbset6.dat