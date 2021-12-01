::!\bin\sh

:: First run of SAPI to find list of peaks

sapi HKLIN %RNASE%\rnase25 SAPIPKS %TEMPRES%\sapi_run1.peaks < %SCRIPTWIN%\sapi1.dat

:: The output is a set of peaks in the SAPIPKS file
:: Run SAPI again to refine these sites and obtain scores
:: using the KAR keyword
::!\bin\sh

:: Second run of SAPI to refine\score possible sites
:: The output is a set of peaks in the SAPIPKS file
:: The list of sites after the KAR keyword was obtained from
:: sapi_run1.exam

sapi HKLIN %RNASE%\rnase25 SAPIPKS %TEMPRES%\sapi_run2.peaks < %SCRIPTWIN%\sapi2.dat


