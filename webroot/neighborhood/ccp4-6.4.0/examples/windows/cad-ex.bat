::!\bin\sh
:: 
:: awa 970408 Version 2
:: updated from origional version to allow it to run on one file

::   an example of combining several files - the files do
::   not haveto be diffrent but this would usually be the case!
::   Ei  refer to ENTRYi ..... - NO SPECIAL SIGNIFICANCE to E!!

cad HKLIN1 %TOXD%\toxd.mtz HKLIN2 %TOXD%\toxd.mtz HKLIN3 %TOXD%\toxd.mtz HKLIN4 %TOXD%\toxd.mtz	HKLOUT %TEMPRES%\toxd_big.mtz < %SCRIPTWIN%\cad1.dat

::   an example of extending native data to P1 +-h,+-k,+l
::   notice that the file header still has P212121 can be
::   changed with mtzutils
cad HKLIN1 %TOXD%\toxd.mtz HKLOUT %TEMPRES%\toxd_p1 < %SCRIPTWIN%\cad2.dat

::

