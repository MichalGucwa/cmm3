::!\bin\sh

:: Examples of using CAD to change dataset info
:: in rnase example data

:: 1. Simple re-naming of crystals and datasets

cad hklin1 %RNASE%\rnase25.mtz hklout %TEMPRES%\rnase_25_drename.mtz < %SCRIPTWIN%\cadrn1.dat

:: 2. Adding wavelengths to dataset headers

cad hklin1 %RNASE%\rnase18.mtz hklout %TEMPRES%\rnase_18_wavel.mtz < %SCRIPTWIN%\cadrn2.dat

:: 3. Moving a column from one dataset to another.
::    This example adds FreeR_flag to the base dataset HKL_base - this
::    may or may not be appropriate

cad hklin1 %RNASE%\rnase25.mtz hklout %TEMPRES%\rnase_25_movecol.mtz < %SCRIPTWIN%\cadrn3.dat
