::!\bin\sh

amore hklin %TOXD%\toxd.mtz hklpck0 %TEMPRES%\toxd_pck0.hkl < %SCRIPTWIN%\bulk1.dat

amore xyzin1 %TOXD%\toxd.pdb xyzout1 %TEMPRES%\toxd_tabled.pdb table1 %TEMPRES%\toxd_table1.tab < %SCRIPTWIN%\bulk2.dat > %TEMPRES%\toxd_tabling.log

prep_bulk < %SCRIPTWIN%\bulk3.dat

bulking < %TEMPRES%\toxd_bulking.inp

:: Bulk results are used for translation and fitting steps
:: We assume we have a rotation solution from somewhere, e.g.
:: an Amore ROTING run.

amore hklpck0 %TEMPRES%\toxd_pck0.hkl table1 %TEMPRES%\toxd_table1.tabs mapout %TEMPRES%\toxd_TF < %SCRIPTWIN%\bulk4.dat > %TEMPRES%\toxd_traing.log

::amore hklpck0 %TEMPRES%\toxd_pck0.hkl table1 %TEMPRES%\toxd_table1.tabs < %SCRIPTWIN%\bulk5.dat