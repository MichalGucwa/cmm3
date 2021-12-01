::! \bin\sh

:: This is a very simple example to test the running of the
:: programs fffear and ffjoin. It is probably not very educational!

IF NOT EXIST %TEMPRES%\toxd_phase_mir.mtz (echo "! run the mlphare.exam procedure first" 1>&2 && GOTO :EOF)

fffear hklin %TEMPRES%\toxd_phase_mir.mtz xyzin %CLIBD%\fraglib\emp-helix-9.pdb xyzout %TEMPRES%\alpha9-rot.pdb < %SCRIPTWIN%\fffear.dat

ffjoin xyzin %TEMPRES%\alpha9-rot.pdb xyzout %TEMPRES%\alpha9-rot-join.pdb < %SCRIPTWIN%\end.dat

