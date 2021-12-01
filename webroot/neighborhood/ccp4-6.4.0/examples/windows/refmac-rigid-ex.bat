::!/bin/sh
:: refmac-rigid.exam

:: A run-all script to run refmac rigid body refinement with the cubic insulin
:: structure 2bn3 (Nanao & Ravelli) and the results of the run-all script
:: scala-complete which will scale, merge and massage the measurements of 
:: same.

echo off

:: bug # 3192 - run-all examples produce harvest files - well to counteract
:: this here set HARVESTHOME to somewhere in $CCP4_SCR

set HARVESTHOME=%CCP4_SCR%

:: check that the input file - %CCP4_SCR%\sc-exam-free.mtz - exists

IF NOT EXIST %TEMPRES%\sc-exam-free.mtz (echo "! run scala-complete.exam first" 1>&2 && GOTO :EOF)

:: FIXME - residual mlkf is the default so this should probably be removed
::
:: FIXME - cubic spacegroups cannot have anisotropic b factors for the 
::        bulk solvent model etc:
::         "lssc anisotropic fixbulk bbulk 200.0"
::

:: run refmac5

refmac5 hklin %TEMPRES%\sc-exam-free.mtz hklout %TEMPRES%\sc-exam-refmac5.mtz xyzin %DATA%\insulin_2bn3.pdb xyzout %TEMPRES%/rb-exam-refined.pdb < %SCRIPTWIN%\refmac-rigid.dat





