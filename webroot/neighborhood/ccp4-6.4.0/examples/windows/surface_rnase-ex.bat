::!\bin\sh -e

:: Example using rnase coordinates for accessible surface
:: calculation

:: Comments
:: --------
:: surface is best run interactively; because of its poor
:: input method a script is difficult to write.
::
:: This is a run of surface which calculates the accessible
:: area for chain A in rnase twice - once for chain A alone
:: and once taking account of the presence of chain B.
::
:: nb since "chain" command only recognises numbers,
:: specify the chains using atom numbers

:: Remove log file (if it already exists)

IF EXIST %TEMPRES%\surface.log (del %TEMPRES%\surface.log)

surface XYZIN1 %RNASE%\rnase.pdb XYZOUT %TEMPRES%\rnase_chn_a.rad < %SCRIPTWIN%\surf-rnase.dat >> %TEMPRES%\surface.log

:: Use 'grep' to extract the total accessible area from
:: each calculation

echo ' Total accessible areas from SURFACE are:'
find "all atoms in calculation" %TEMPRES%\surface.log

