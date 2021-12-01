::!\bin\sh 
::
:: Run truncate after scala to give F's from intensities
:: 

IF NOT EXIST %TEMPRES%\aucn_mrg.mtz (echo '! run scala.exam first' 1>&2 && GOTO :EOF)

truncate hklin %TEMPRES%\aucn_mrg.mtz hklout %TEMPRES%\aucn_trn.mtz < %SCRIPTWIN%\truncate1.dat

:: Second example of running TRUNCATE on Fs. You might
:: do this if you already have Fs but want to look at the
:: output graphs of TRUNCATE

truncate hklin %RNASE%\rnase18.mtz < %SCRIPTWIN%\truncate2.dat



