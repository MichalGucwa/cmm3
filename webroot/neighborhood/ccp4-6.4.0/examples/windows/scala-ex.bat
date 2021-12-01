
na4tomtz hklin %DATA%\aucn.na4 hklout %TEMPRES%\aucn

sortmtz hklin %TEMPRES%\aucn.mtz hklout %TEMPRES%\aucn_sor.mtz < %SCRIPTWIN%\scala1.dat

scala hklin %TEMPRES%\aucn_sor.mtz hklout   %TEMPRES%\aucn_mrg.mtz scales %TEMPRES%\aucn.scales rogues %TEMPRES%\aucn.rogues normplot %TEMPRES%\aucn.norm anomplot %TEMPRES%\aucn.anom < %SCRIPTWIN%\scala2.dat

truncate hklin %TEMPRES%\aucn_mrg.mtz hklout %TEMPRES%\aucn_trn.mtz < %SCRIPTWIN%\scala3.dat





