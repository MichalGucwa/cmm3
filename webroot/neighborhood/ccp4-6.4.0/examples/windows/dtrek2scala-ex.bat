::!\bin\csh -fe
::

dtrek2scala hklout %TEMPRES%\HEWL-test.dtrek2scala.mtz < %SCRIPTWIN%\dtrek2scala1.dat

sortmtz hklout %TEMPRES%\HEWL-test.sort.mtz < %SCRIPTWIN%\dtrek2scala2.dat

IF EXIST %TEMPRES%\HEWL-test.scales (move %TEMPRES%\HEWL-test.scales %TEMPRES%\HEWL-test.scales.last)

scala hklin %TEMPRES%\HEWL-test.sort.mtz hklout %TEMPRES%\HEWL-test.scala.mtz scales %TEMPRES%\HEWL-test.scales rogues %TEMPRES%\HEWL-test.rogues normplot %TEMPRES%\HEWL-test.norm.xmgr anomplot %TEMPRES%\HEWL-test.anom.xmgr plot %TEMPRES%\HEWL-test.surface.plt < %SCRIPTWIN%\dtrek2scala3.dat

truncate hklin  %TEMPRES%\HEWL-test.scala.mtz hklout %TEMPRES%\HEWL-test.truncate.mtz < %SCRIPTWIN%\dtrek2scala4.dat

:: Now put everything back together into one file ...

cad    hklin1 %TEMPRES%\HEWL-test.truncate.mtz hklout %TEMPRES%\HEWL-test.cad.mtz < %SCRIPTWIN%\dtrek2scala5.dat

:: ... and analyse with scaleit

scaleit hklin %TEMPRES%\HEWL-test.cad.mtz hklout %TEMPRES%\HEWL-test.scaleit.mtz < %SCRIPTWIN%\dtrek2scala6.dat
