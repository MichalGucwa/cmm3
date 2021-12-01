::!\bin\sh

:: An example of a map cutting procedure, e.g. for use in a
:: molecular replacement search.

:: I'm not entirely sure if this is a sensible example,
:: but so far it's our only runnable test of maprot

:: The basic idea is to cut out the part of the 3fo2fc map
:: which covers one molecule, and place it in a virtual cell

IF  NOT EXIST %TEMPRES%\3fo2fc.map ( echo "! Run 3fo2fcmap first" 1>&2 && GOTO :EOF )

:: Start with 3fo2fc.map from 3fo2fcmap example.
:: This map has true spacegroup and cell, and covers 1 asymmetric unit

:: Create mask covering just one molecule

:: select protein only

pdbset XYZIN %TOXD%\toxd.pdb XYZOUT %TEMPRES%\toxd_protein.pdb < %SCRIPTWIN\%mapcutting1.dat

:: Now make mask in P1

ncsmask xyzin %TEMPRES%\toxd_protein.pdb mskout %TEMPRES%\toxd.msk < %SCRIPTWIN%\end.dat

:: change the extent of MAPIN to match that of MAPLIM

mapmask MAPIN %TEMPRES%\3fo2fc.map MAPLIM %TEMPRES%\toxd.msk MAPOUT %TEMPRES%\toxd_1.map < %SCRIPTWIN\%mapcutting2.dat

:: transfer density from WRKIN into a virtual 75A cell, output to CUTOUT

maprot WRKIN %TEMPRES%\toxd_1.map MSKIN %TEMPRES%\toxd.msk CUTOUT %TEMPRES%\toxd_cut.map < %SCRIPTWIN\%mapcutting3.dat

