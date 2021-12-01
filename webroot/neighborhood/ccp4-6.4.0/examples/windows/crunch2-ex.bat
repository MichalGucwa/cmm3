::!/bin/sh

:: This is a short example for the run-all script.
:: Normally TRY and NCYC would be set higher (defaults
:: are TRY 1 20 and NCYC 400).

crunch2 HKLIN %DATA%\oligo.drear HITS %TEMPRES%\oligo.hits < %SCRIPTWIN%\crunch2.dat

:: Clean out sorted file so test can be run again without taking hours

del %CEXAM%\windows\sorted.xyz
