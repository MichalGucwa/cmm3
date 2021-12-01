::!\bin\sh 

::example of bplot
::with one input file, all keywords can be defaulted

bplot XYZIN1 %TOXD%\toxd.pdb PLOT %TEMPRES%\toxd.plo < %SCRIPTWIN%\bplot.dat

::view with xplot84driver, or convert to postscript with pltdev
