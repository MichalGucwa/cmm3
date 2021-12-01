::!\bin\sh

:: Analyse ADPs including all main chain atoms

anisoanl xyzin %DATA%\1a2p.pdb tlsin %DATA%\1a2p_1.tls psout %TEMPRES%\1a2ps_1.ps < %SCRIPTWIN%\anisoanl1.dat

:: Split into 3 groups, and fit TLS parameters

anisoanl xyzin %DATA%\1a2p.pdb tlsin %DATA%\1a2p_2.tls xyzout %TEMPRES%\1a2p_anisoanl.pdb tlsout %TEMPRES%\1a2p_anisoanl.tls psout %TEMPRES%\1a2ps_2.ps < %SCRIPTWIN%\anisoanl2.dat


:: Analyse TLS parameters from previous fitting procedure.

tlsanl xyzin %DATA%\1a2p.pdb tlsin %TEMPRES%\1a2p_anisoanl.tls xyzout %TEMPRES%\1a2p_tlsanl.pdb < %SCRIPTWIN%\end.dat
:: Extract sample results for testing purposes - these can
:: be compared with runs with different versions or on different
:: platforms

echo " " >> %TEMPRES%\sample_results
echo " *** anisoanl.exam *** " >> %TEMPRES%\sample_results
echo " " >> %TEMPRES%\sample_results
find "[TLS]    " %TEMPRES%\1a2p_anisoanl.tls >> %TEMPRES%\sample_results
