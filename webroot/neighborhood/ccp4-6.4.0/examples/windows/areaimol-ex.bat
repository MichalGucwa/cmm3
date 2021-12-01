::!\bin\sh

::
:: Example scripts for areaimol using toxd data
::

:: used to distinguish different runs in html logfile
::CCP_PROGRAM_ID=run1
::export CCP_PROGRAM_ID

::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
::
:: Simple area calculation (verbose output)
::
::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::

areaimol XYZIN %TOXD%\toxd.pdb XYZOUT %TEMPRES%\sarea1.brk < %SCRIPTWIN%\areaimol1.dat

::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
::
:: Water differences with lattice symmetry contacts
:: and probe radius set to 1.6 A
::
::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::

::CCP_PROGRAM_ID=run2

areaimol XYZIN %TOXD%\toxd.pdb  < %SCRIPTWIN%\areaimol2.dat

::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
::
:: Differences due to intermolecular lattice
:: contacts, ignoring waters
::
::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::

::CCP_PROGRAM_ID=run3

areaimol XYZIN %TOXD%\toxd.pdb XYZOUT %TEMPRES%\sdiff1.brk < %SCRIPTWIN%\areaimol3.dat

::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
::
:: Area change due to absence of a residue
::
::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::

:: First: make an altered version of toxd by
:: cutting out LYS A residues using the unix
:: 'grep' command

find /V "LYS A   5" %TOXD%\toxd.pdb > %TEMPRES%\toxd_1.pdb

:: Then obtain the resulting area differences

::CCP_PROGRAM_ID=run4

areaimol XYZIN %TOXD%\toxd.pdb XYZIN2 %TEMPRES%\toxd_1.pdb XYZOUT %TEMPRES%\sdiff2.brk < %SCRIPTWIN%\areaimol4.dat

