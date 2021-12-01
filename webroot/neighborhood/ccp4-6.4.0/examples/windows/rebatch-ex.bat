::!\bin\sh 
::
:: run rebatch
:: 

na4tomtz hklin %DATA%\aucn.na4 hklout %TEMPRES%\aucn.mtz

:: used to distinguish different runs in html logfile
::CCP_PROGRAM_ID=run1
::export CCP_PROGRAM_ID
::
:: REBATCH - alter batch numbers in an unmerged MTZ file
 
rebatch hklin %TEMPRES%\aucn.mtz hklout aucn_rebatch1.mtz < %SCRIPTWIN%\rebatch1.dat

:: Alternative keyword commands for REBATCH
:: 
:: batch 6 to 8 start 101 step 2
:: batch 5 6 7 add 10
:: batch all add 10
:: batch maxwidth 1.0
::CCP_PROGRAM_ID=run2

rebatch hklin %TEMPRES%\aucn.mtz hklout aucn_rebatch2.mtz < %SCRIPTWIN%\rebatch2.dat

::CCP_PROGRAM_ID=run3

rebatch hklin %TEMPRES%\aucn.mtz hklout aucn_rebatch3.mtz < %SCRIPTWIN%\rebatch3.dat









