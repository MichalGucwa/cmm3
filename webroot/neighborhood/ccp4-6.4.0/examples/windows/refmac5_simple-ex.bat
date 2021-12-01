::!/bin/sh

:: this is an example script for bug # 3241 which came out of the end of the 
:: Mr Bump example

set HARVESTHOME=%CCP4_SCR%

:: Simple example of using REFMAC5 with default options.

refmac5 HKLIN  %RNASE%\rnase18.mtz HKLOUT %CCP4_SCR%\rnase_simple_out.mtz XYZIN  %RNASE%\rnase.pdb XYZOUT %CCP4_SCR%\rnase_simple_out.pdb < %SCRIPTWIN%\refmac5_simple.dat





