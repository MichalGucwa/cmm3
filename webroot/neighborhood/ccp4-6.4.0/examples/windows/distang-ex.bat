::!\bin\sh
::   Standard distance angle calculation.
:: Very fast.
:: allows  useful limits to be set.
::

distang	XYZIN %TOXD%\toxd.pdb < %SCRIPTWIN%\distang1.dat

::

distang	XYZIN %TOXD%\toxd.pdb < %SCRIPTWIN%\distang2.dat

 ::   Angles too.

::
::   Calculate distance angles for B2 c-unique contacts.
::

distang	XYZIN %TOXD%\toxd.pdb < %SCRIPTWIN%\distang3.dat


