::!\bin\sh

:: An example of dealing with fractional coordinates from mlphare sites
:: or direct methods.

:: mlphare-type heavy atom coordinates; yes the blank line currently
:: seems necessary...

copy %SCRIPTWIN%\fract-orth1.dat %TEMPRES%\mlphare_sites.frc

:: Generate PDB from fractional, inter alia.  `vectors' will also
:: generate the Patterson vectors and has yet another variety of
:: coordinate input format.

havecs XYZIN %TEMPRES%\mlphare_sites.frc XYZOUT %TEMPRES%\mlphare_sites.pdb UVWOUT %TEMPRES%\mlphare_sitesuvw.pdb < %SCRIPTWIN%\fract-orth2.dat

:: coordconv won't handle mlphare format but will do others:

coordconv xyzin %TEMPRES%\mlphare_sites.pdb xyzout %TEMPRES%\mlphare_sites.yorkfrac < %SCRIPTWIN%\fract-orth3.dat

coordconv xyzin %TEMPRES%\mlphare_sites.yorkfrac xyzout %TEMPRES%\mlphare_sites.yorkpdb < %SCRIPTWIN%\fract-orth4.dat
