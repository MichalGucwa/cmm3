::!\bin\sh

mlphare hklin %TOXD%\toxd.mtz  hklout %TEMPRES%\toxd_phase_mirph.mtz < %SCRIPTWIN%\phistats1.dat

:: Read in coordinates to calculate structure factors. 

sfall hklin %TEMPRES%\toxd_phase_mirph.mtz hklout %TEMPRES%\toxd_sfph.mtz xyzin %TOXD%\toxd.pdb xyzout %TEMPRES%\junk.pdb < %SCRIPTWIN%\phistats2.dat

phistats hklin %TEMPRES%\toxd_sfph.mtz < %SCRIPTWIN%\phistats3.dat


