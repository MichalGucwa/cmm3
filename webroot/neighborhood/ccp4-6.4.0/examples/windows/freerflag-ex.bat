::!\bin\sh

:: NOTE: freerflag is included in the script uniqueify, and in general
:: you should not need to run it on its own.

:::::::::::::: starting from CCP4 file (for starting from X-PLOR data with free R,
::       see also f2mtz.exam (and use `cad' afterwards) as well as
::       mtz2various.exam to go the other way)

::  Take original mtz file.
::  HKLOUT will have all items in HKLIN plus a FreeRflag
::  On average, 5% of the data has a particular flag in the range (0,19)
::  which can be used for exclusion from refinement.

freerflag HKLIN %TOXD%\toxd_old HKLOUT %TEMPRES%\toxd_free < %SCRIPTWIN%\freerflag1.dat

::
::  If you need to extend your data generate freerflag first,
::  so that all equivalent reflections have the same status.
::
::   an example of extending native data to P1 +-h,+-k,+l

cad HKLIN1 %TEMPRES%\toxd_free HKLOUT %TEMPRES%\toxd_free_p1 < %SCRIPTWIN%\freerflag2.dat

:::::: Example of COMPLETE keyword ::::::::::

:: We take a 1.8 A dataset from rnase18.mtz and combine it with a
:: freeR column from a 2.5 A dataset rnase25.mtz  In the output
:: file from CAD, there are thus no freeR flags for the resolution
:: range 1.8 - 2.5 A.
:: We then use FREERFLAG to extend the freeR flags out to 1.8 A,
:: while keeping the original ones unchanged.

cad hklin1 %RNASE%\rnase18.mtz hklin2 %RNASE%\rnase25.mtz hklout %TEMPRES%\rnase_cad.mtz < %SCRIPTWIN%\freerflag3.dat

freerflag hklin %TEMPRES%\rnase_cad.mtz hklout %TEMPRES%\rnase_free.mtz < %SCRIPTWIN%\freerflag4.dat


