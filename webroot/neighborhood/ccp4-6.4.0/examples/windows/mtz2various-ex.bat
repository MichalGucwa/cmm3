::!\bin\sh

:: Convert MTZ file (including free R) to CNS format with anomalous data.
:: F(+h +k +l) and F(-h -k -l) are reconstructed from FP and DP.
:: CNS header lines are written automatically.

mtz2various hklin %TOXD%\toxd.mtz HKLOUT %TEMPRES%\toxd.hkl  < %SCRIPTWIN%\mtz2var1.dat

:: Convert MTZ file to user-defined format.
:: MNFs in input file are output as -999.0 (default reflections are not output
:: if they have a MNF entry).

mtz2various HKLIN %TOXD%\toxd.mtz HKLOUT %TEMPRES%\toxd.user  < %SCRIPTWIN%\mtz2var2.dat

:: Write out a reflection file of the squares of the isomorphous
:: differences between a heavy atom dataset and a native one. The output
:: can be used in SHELX to solve heavy atom locations by direct methods.

mtz2various HKLIN %TOXD%\toxd.mtz HKLOUT %TEMPRES%\toxd.shelx < %SCRIPTWIN%\mtz2var3.dat

:: Convert to user-defined format using dummy labels DUM1 etc

mtz2various HKLIN %TOXD%\toxd.mtz HKLOUT %TEMPRES%\junk.hkl < %SCRIPTWIN%\mtz2var4.dat

:: Convert to mmCIF format

mtz2various HKLIN %TOXD%\toxd.mtz HKLOUT %TEMPRES%\junk.cif <  %SCRIPTWIN%\mtz2var5.dat

::

