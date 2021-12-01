::!\bin\sh

IF NOT EXIST %TEMPRES%\rnase_out.tls (echo "! run the refmac5_tls.exam procedure first" 1>&2 && GOTO :EOF)

:: Analyse TLS parameters from previous fitting procedure.

tlsanl xyzin %TEMPRES%\rnase_out.pdb tlsin %TEMPRES%\rnase_out.tls xyzout %TEMPRES%\rnase_tlsanl.pdb < %SCRIPTWIN%\tlsanl.dat

:: Extract sample results for testing purposes - these can
:: be compared with runs with different versions or on different
:: platforms

echo " " >> %TEMPRES%\sample_results
echo " *** tlsanl.exam *** " >> %TEMPRES%\sample_results
echo " " >> %TEMPRES%\sample_results
find "A   1 " %TEMPRES%\rnase_tlsanl.pdb >> %TEMPRES%\sample_results

