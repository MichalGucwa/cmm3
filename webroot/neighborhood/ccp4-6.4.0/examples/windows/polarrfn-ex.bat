::!\bin\sh 
::   Program to calculate self rotation function.

polarrfn HKLIN  %TOXD%\toxd.mtz MAPOUT %TEMPRES%\self.map  plot %TEMPRES%\polarrfn < %SCRIPTWIN%\polarrfn.dat

:: convert to PostScript
pltdev -i %TEMPRES%\polarrfn.plo -o %TEMPRES%\polarrfn.ps

:: this generates a stereographic net to overlay on the plot

stnet plot %TEMPRES%\net.plo
pltdev -i %TEMPRES%\net.plo -o %TEMPRES%\net.ps

del %TEMPRES%\polarrfn.plo %TEMPRES%\net.plo
::
