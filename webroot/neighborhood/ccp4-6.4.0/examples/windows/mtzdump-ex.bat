::!\bin\sh 
:: see also the script $CETC\mtzdmp for an easier way to run mtzdump
:: E.g. (1)
:: Simple dump of reflections
::

mtzdump HKLIN %TOXD%\toxd.mtz	< %SCRIPTWIN%\mtzdump1.dat

:: E.g. (2)
:: Production of statistics

mtzdump HKLIN %TOXD%\toxd.mtz	< %SCRIPTWIN%\mtzdump2.dat

:: E.g. (3)
:: Dump of header including symmetry information, reflection statistics 
:: and all reflections in the file.

mtzdump HKLIN %TOXD%\toxd.mtz	< %SCRIPTWIN%\mtzdump3.dat

