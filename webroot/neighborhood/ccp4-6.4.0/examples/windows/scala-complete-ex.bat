::!/bin/sh
:: scala-complete.exam
:: 
:: A run-all script which runs pointless, scala, truncate & sfcheck with 
:: some real cubic insulin data (see bug :: 3129) with the intention of 
:: making use of a wider list of keywords for these programs. The resulting
:: reflection file may also be used in a refmac RB refinement example.
::
:: Data used comes from SRS 14.2 measured by John Cowan.
::
:: bug # 3192 - run-all examples produce harvest files - well to counteract 
:: this here set HARVESTHOME to somewhere in $CCP4_SCR

set HARVESTHOME=%CCP4_SCR%

:: run pointless - though we know the data are in the correct pg

pointless hklin %DATA%\insulin_unmerged.mtz  hklout %CCP4_SCR%\sc-exam-in.mtz < %SCRIPTWIN%\scala-complete1.dat

:: run reindex to put the correct spacegroup for insulin - I213 - into 
:: the header

reindex hklin %CCP4_SCR%\sc-exam-in.mtz hklout %CCP4_SCR%\sc-exam-i213.mtz < %SCRIPTWIN%\scala-complete2.dat

:: now sort the data 

sortmtz hklin %CCP4_SCR%\sc-exam-i213.mtz hklout %CCP4_SCR%\sc-exam-sort.mtz < %SCRIPTWIN%\scala-complete3.dat

:: and run scala

scala hklin %CCP4_SCR%\sc-exam-sort.mtz hklout %CCP4_SCR%\sc-exam-scale.mtz scales %CCP4_SCR%\sc-exam.scales rogues %CCP4_SCR%\sc-exam.rogues plot %CCP4_SCR%\sc-exam.plot rogueplot %CCP4_SCR%\sc-exam.rogueplot correlplot %CCP4_SCR%\sc-exam.correlplot normplot %CCP4_SCR%\sc-exam.normplot < %SCRIPTWIN%\scala-complete3.dat


:: run scala again for output unmerged - this is to provide test data for a
:: new chef example

scala hklin %CCP4_SCR%\sc-exam-sort.mtz hklout %CCP4_SCR%\sc-exam-scale-unmerged.mtz scales %CCP4_SCR%\sc-exam-unmerged.scales rogues %CCP4_SCR%\sc-exam.rogues plot %CCP4_SCR%\sc-exam.plot rogueplot %CCP4_SCR%\sc-exam.rogueplot correlplot %CCP4_SCR%\sc-exam.correlplot normplot %CCP4_SCR%\sc-exam.normplot < %SCRIPTWIN%\scala-complete5.dat

:: and then truncate

truncate hklin %CCP4_SCR%\sc-exam-scale.mtz hklout %CCP4_SCR%\sc-exam-trunc.mtz < %SCRIPTWIN%\scala-complete6.dat

:: and finally add the FreeR flag

freerflag hklin %CCP4_SCR%\sc-exam-trunc.mtz hklout %CCP4_SCR%\sc-exam-free.mtz < %SCRIPTWIN%\scala-complete6.dat



  
