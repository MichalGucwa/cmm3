::!/bin/sh

:: Example of refinement of twinned data by Refmac.
:: 1rxf artificial data, pdb uses random offsets.
:: Uses intensity likelihood function.

refmac5 XYZIN %DATA%\1rxf_randomise.pdb HKLIN %DATA%\1rxf.mtz XYZOUT %CCP4_SCR%\1rxf_out.pdb HKLOUT %CCP4_SCR%\1rxf_out.mtz < %SCRIPTWIN%\refmac_twin.dat
