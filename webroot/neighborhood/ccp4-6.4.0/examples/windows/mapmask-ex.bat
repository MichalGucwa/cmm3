::!\bin\sh
:: awa 970408 ver 1.1
::
:: mapmask - map\mask extend program 
::


:: Firstly check to see if sf_calc has been
:: run

IF NOT EXIST %TEMPRES%\toxd_fc.map ( echo '! running sf_calc first.' 1>&2 && echo '! see %SCRIPTWIN%\sf_calc-ex .' 1>&2 &&  %SCRIPTWIN%\sf_calc-ex )

:: Secondly check if it worked!

if  NOT exist %TEMPRES%\toxd_fc.map ( echo '! sf_calc did not run correctly.' 1>&2 && echo '! run it by hand before trying this script again.' 1>&2 && GOTO :EOF )

:: To Extend A Map (See Extend):
::

mapmask mapin %TEMPRES%\toxd_fc.map mapout %TEMPRES%\toxd_ins1.ext xyzin %TOXD%\toxd.pdb < %SCRIPTWIN%\mapmask1.dat

:: Or:
::

mapmask mapin %TEMPRES%\toxd_fc.map mapout %TEMPRES%\toxd_ins2.ext < %SCRIPTWIN%\mapmask2.dat

:: To Resection A Map:
::

mapmask mapin  %TEMPRES%\toxd_fc.map mapout %TEMPRES%\toxd_inszyx.map < %SCRIPTWIN%\mapmask3.dat

:: To Rescale A Map: (r'=2r+1)
::

mapmask mapin %TEMPRES%\toxd_fc.map mapout %TEMPRES%\toxd_insscaled.map < %SCRIPTWIN%\mapmask4.dat

:: To Make A Mask From A Map (Mask Covers Region Of Map > 0.5):
::

mapmask mapin %TEMPRES%\toxd_fc.map mskout %TEMPRES%\toxd_ins1.msk < %SCRIPTWIN%\mapmask5.dat

:: To Make A Mask From A Map To Cover 70% Of The Unit Cell:
::

mapmask mapin %TEMPRES%\toxd_fc.map mskout %TEMPRES%\toxd_ins2.msk < %SCRIPTWIN%\mapmask6.dat

:: To Make A Map From A Mask:
::

mapmask mapin %TEMPRES%\toxd_ins1.msk mapout %TEMPRES%\toxd_from_msk.map < %SCRIPTWIN%\mapmask7.dat

:: To print out a mask section z=5 of all points above 0.9:
::

mapmask mapin %TEMPRES%\toxd_fc.map < %SCRIPTWIN%\mapmask8.dat

:: To print out alternate map x-sections, scaled x100:
::

mapmask mapin %TEMPRES%\toxd_fc.map < %SCRIPTWIN%\mapmask9.dat

:: To Make A Solvent Envelope, 2.5 Angstroms About Atoms.
::
:: Use sfall to construct density for all points up to but
:: not exceeding 2.5 A from atoms. Then use mapmask to select
:: this region.

:: Step 1: sfall

sfall xyzin %TOXD%\toxd.pdb mapout  %TEMPRES%\junk.map < %SCRIPTWIN%\mapmask10.dat

:: Step 2: mapmask

mapmask mapin  %TEMPRES%\junk.map mapout  %TEMPRES%\bar.msk < %SCRIPTWIN%\mapmask11.dat


