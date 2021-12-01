::!\bin\sh 

:: Simple example of using REFMAC5 with TLS option.
:: (In fact, TLS gives no great improvement in this case, but it
:: shows the method.)

refmac5 HKLIN  %RNASE%\rnase18.mtz HKLOUT %TEMPRES%\rnase_out.mtz TLSIN  %RNASE%\rnase.tls TLSOUT %TEMPRES%\rnase_out.tls XYZIN  %RNASE%\rnase.pdb XYZOUT %TEMPRES%\rnase_out.pdb < %SCRIPTWIN%\refmac5_tls.dat
