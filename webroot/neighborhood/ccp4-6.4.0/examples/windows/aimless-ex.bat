::# bug # 3192 - run-all examples produce harvest files - well to counteract
::# this here set HARVESTHOME to somewhere in $CCP4_SCR
::
::HARVESTHOME=$CCP4_SCR
::export HARVESTHOME

na4tomtz hklin %DATA%\aucn.na4 hklout %TEMPRES%\aucn

::#
::# aimless - calculating batch scale factors & merging
::# Simple case - single scale and B factor for each batch
::# see $CEXAM/unix/non-runnable/scala.exam for other examples
::#
aimless hklin %TEMPRES%\aucn.mtz hklout %TEMPRES%\aucn_mrg.mtz scales %TEMPRES%\aucn.scales rogues %TEMPRES%\aucn.rogues normplot %TEMPRES%\aucn.norm anomplot %TEMPRES%\aucn.anom rogueplot %TEMPRES%\aucn.rogueplot correlplot %TEMPRES%\aucn.correlplot < %SCRIPTWIN%\aimless.dat
::#
::#
::ctruncate -hklin $CCP4_SCR/aucn_mrg.mtz \
::   -hklout $CCP4_SCR/aucn_ctr.mtz \
::   -colin "/*/*/[IMEAN,SIGIMEAN]" -nres 745
::
