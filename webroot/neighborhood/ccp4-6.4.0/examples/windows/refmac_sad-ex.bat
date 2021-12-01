::!/bin/sh

:: Example of SAD phasing and substructure refinement by Refmac.

refmac5  HKLIN %DATA%\gere.mtz XYZIN %DATA%\gere_heavy.pdb XYZOUT %TEMPRES%\gere_heavy_out.pdb HKLOUT %TEMPRES%\gere_out.mtz < %SCRIPTWIN%\refmac_sad.dat

:: Example of SAD refinement of incomplete model.

refmac5 HKLIN %DATA%\gere.mtz XYZIN %DATA%\gere_incompl.pdb XYZOUT %CCP4_SCR%\gere_incompl_out.pdb HKLOUT %CCP4_SCR%\gere_out.mtz < %SCRIPTWIN%\refmac_sad2.dat



