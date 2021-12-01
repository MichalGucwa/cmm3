::!\bin\sh

angles xyzin %TOXD%\toxd.pdb ANGOUT %TEMPRES%\junk.a PLOT %TEMPRES%\angles.plot < %SCRIPTWIN%\angles.dat

pltdev -dev ps -aut -i %TEMPRES%\angles.plot -o %TEMPRES%\plot84.ps


