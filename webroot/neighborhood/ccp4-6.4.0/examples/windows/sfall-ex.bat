::!\bin\sh -e

::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
::
:: Simple SFALL Examples using rnase data
::
:: These are simple examples of using SFALL
:: Refer to documentation for more details\options.
::
:: (See also %CEXAM%\unix\runnable\sf-calc)
::
::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::

::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:: 1. Generate Structure Factors from Coordinates
::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::

sfall XYZIN %RNASE%\rnase.pdb HKLIN %RNASE%\rnase25.mtz HKLOUT %TEMPRES%\rnase25_calc.mtz < %SCRIPTWIN%\sfall1.dat

::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:: 2. Generate map from coordinates
::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::

sfall XYZIN %RNASE%\rnase.pdb MAPOUT %TEMPRES%\rnase_atm.map < %SCRIPTWIN%\sfall2.dat

::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:: 3. Generate structure factors from a map
::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::

sfall MAPIN %TEMPRES%\rnase_atm.map HKLOUT %TEMPRES%\rnase_junk.mtz < %SCRIPTWIN%\sfall3.dat
