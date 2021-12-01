::!/bin/sh

:: Tabulate/graph f', f'' for various wavelengths, elements.
:: Run xloggraph on the output.

crossec < %SCRIPTWIN%\crossec1.dat

:: As above but for U and with verbose output.

crossec < %SCRIPTWIN%\crossec2.dat

:: Now for Os. Same wavelengths, but in old long-winded style.

crossec < %SCRIPTWIN%\crossec3.dat
