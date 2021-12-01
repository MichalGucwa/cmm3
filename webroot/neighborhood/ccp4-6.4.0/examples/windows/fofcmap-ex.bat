::!\bin\sh

::   Calculate an Fo-Fc map and find position of significant peaks

::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
::   Add Fc and Phic to the reflection file
::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::

sfall xyzin %TOXD%\toxd.pdb hklin %TEMPRES%\toxd_phase_mir.mtz hklout %TEMPRES%\toxd_fc < %SCRIPTWIN%\fofcmap1.dat

::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
::  Scale the Fc's to the Fo's
::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::

rstats hklin %TEMPRES%\toxd_fc hklout %TEMPRES%\toxd_fofc < %SCRIPTWIN%\fofcmap2.dat

sigmaa  hklin %TEMPRES%\toxd_fofc hklout %TEMPRES%\toxd_fofc_sa < %SCRIPTWIN%\fofcmap3.dat

::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
::  Calculate the "2Fo-Fc  map for an asymmetric unit
::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::

fft hklin %TEMPRES%\toxd_fofc_sa mapout %TEMPRES%\toxd_2fofc.map < %SCRIPTWIN%\fofcmap4.dat

::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
::  Extend the difference map to cover the molecule + 4 Ang
::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::

mapmask mapin %TEMPRES%\toxd_2fofc.map  mapout %TEMPRES%\toxd_2fofc_ext.map  xyzin %TOXD%\toxd.pdb < %SCRIPTWIN%\fofcmap5.dat

::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
::  Calculate the difference map for an asymmetric unit
::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::

fft hklin %TEMPRES%\toxd_fofc_sa mapout %TEMPRES%\toxd_fofc.map < %SCRIPTWIN%\fofcmap6.dat

::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
::  Extend the difference map to cover the molecule + 4 Ang
::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::

mapmask mapin %TEMPRES%\toxd_fofc.map  mapout %TEMPRES%\toxd_fofc_ext.map  xyzin %TOXD%\toxd.pdb < %SCRIPTWIN%\fofcmap5.dat

::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
::  Find position of significant peaks (more than 3.5 sigma) in extended map
::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::

peakmax mapin %TEMPRES%\toxd_fofc_ext.map xyzout %TEMPRES%\toxd_fofc.peaks < %SCRIPTWIN%\fofcmap7.dat

::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
::  Which residues are near (within 3.5 Ang) these peaks? 
::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::

watpeak xyzin %TOXD%\toxd.pdb peaks %TEMPRES%\toxd_fofc.peaks xyzout %TEMPRES%\toxd_watpeaks.pdb < %SCRIPTWIN%\fofcmap8.dat

