::!\bin\sh
:: awa 970325 ver 1.0
::
:: hgen - generate hydrogen atom positions for proteins
::

hgen xyzin %TOXD%\toxd.pdb xyzout %TEMPRES%\toxd_hydrogens-hgen.pdb < %SCRIPTWIN%\hgen1.dat

hgen xyzin %TOXD%\toxd.pdb xyzout %TEMPRES%\toxd_all-hgen.pdb < %SCRIPTWIN%\hgen2.dat


