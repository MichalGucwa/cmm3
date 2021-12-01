::! \bin\sh

:: Accessible surface area calculation.

:: First calculation flags subsets of atoms. Output
:: file is RAD format which will be input into next run.

:: This falls down. For SUBSET option, need to set all flags.
:: Put default into program??

surface xyzin1 %TOXD%\toxd.pdb xyzout %TEMPRES%\toxd.rad < %SCRIPTWIN%\surface.dat



