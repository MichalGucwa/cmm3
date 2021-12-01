::!\bin\sh

:: This program checks that harvest files are in valid mmCIF format

cross_validate %DATA%\red_aucn.scala < %SCRIPTWIN%\end.dat

:: When the 'cross' keyword is used at the end of the script, the program checks that
:: the data between the two files is consistant

cross_validate %DATA%\red_aucn.scala %DATA%\red_aucn.truncate < %SCRIPTWIN%\end.dat
