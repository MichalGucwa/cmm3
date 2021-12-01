::! \bin\sh

:: Generate 4 copies of toxd model in unit cell

gensym xyzin %TOXD%\toxd.pdb xyzout %TEMPRES%\toxd_exp.pdb < %SCRIPTWIN%\gensym1.dat

:: Generate symmetry mates of heavy atom sites.
:: Output those that lie in small part of unit cell.

gensym xyzout %TEMPRES%\gensites < %SCRIPTWIN%\gensym2.dat
