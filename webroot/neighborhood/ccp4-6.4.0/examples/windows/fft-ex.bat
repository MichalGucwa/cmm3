::!\bin\csh -f
:: awa970502 version 1.1
:: examples taken from the origional documentation

::
:: Calculate difference patterson Example
::

::  Section along all 3 axes to make it easy to contour Harker sections.
::  Do all maps over whole asymmetric unit to be sure each section
::  is on the same scale.
::   X sections
::

fft HKLIN %TOXD%\toxd MAPOUT %TEMPRES%\toxd_aupatt_x < %SCRIPTWIN%\fft1.dat

::   Y sections
::
fft HKLIN %TOXD%\toxd MAPOUT %TEMPRES%\toxd_aupatt_y < %SCRIPTWIN%\fft2.dat

::   Z sections
::
fft HKLIN %TOXD%\toxd MAPOUT %TEMPRES%\toxd_aupatt_z < %SCRIPTWIN%\fft3.dat

:: 
:: Calculate anomalous difference patterson Example
::

::   X sections
::
fft HKLIN %TOXD%\toxd MAPOUT %TEMPRES%\toxd_auanopatt_x < %SCRIPTWIN%\fft4.dat

:: Extract sample results for testing purposes - these can
:: be compared with runs with different versions or on different
:: platforms

echo " " > %TEMPRES%\sample_results
echo " *** fft.exam *** " > %TEMPRES%\sample_results
echo " " > %TEMPRES%\sample_results

mapdump mapin %TEMPRES%\toxd_auanopatt_x.map < %SCRIPTWIN%\end.dat > %TEMPRES%\junk

find "Mean density" %TEMPRES%\junk > %TEMPRES%\sample_results
find "Rms deviation from mean density" %TEMPRES%\junk > %TEMPRES%\sample_results

del %TEMPRES%\junk



