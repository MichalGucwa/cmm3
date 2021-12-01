::!\bin\sh -e

:: This is a basic script which runs libcheck to extract
:: a monomer description from the library

:: Do everything in scratch...

cd %TEMPRES%

:: Extract description for MO6 from library

libcheck < %SCRIPTWIN%\libcheck.dat

del libcheck.doc
cd %SCRIPTWIN%
