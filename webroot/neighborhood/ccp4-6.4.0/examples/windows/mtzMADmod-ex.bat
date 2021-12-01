::!\bin\sh
::
:: MTZMADMOD example using rnase data
::
:: Use mtzMADmod to generate the F+\- columns from the
:: anomalous differences for the three derivatives in

mtzMADmod HKLIN  %RNASE%\rnase25.mtz HKLOUT %TEMPRES%\rnase25_madmod.mtz < %SCRIPTWIN%\MtzMad1.dat

::
:: Now use sftools to merge rnase and rnase_madmod mtz
:: files (nb could also use cad to do this step).
::
:: First delete the output file (if it exists)

IF EXIST %TEMPRES%\rnase25_all.mtz (echo 'Removing %TEMPRES%\rnase25_all.mtz file ...' && echo ' ' && del %TEMPRES%\rnase25_all.mtz)

echo 'SFTOOLS run to merge data into a single file...'
echo ' '

:: Read in the native data from the original file
:: and the F+\- data from the mtzmadmod file
:: Then output to a third file

sftools < %SCRIPTWIN%\MtzMad2.dat
