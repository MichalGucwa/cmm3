::! \bin\sh

:: Wrap-around script for $CETC\uniqueify
:: Completes the dataset by merging output of unique with
:: datafile (using cad). Also adds free-R flag column or
:: completes an existing one.
::
:: Replace missing data with Missing Number Flags (in this case NaNs).

mtzmnf hklin %TOXD%\toxd_old.mtz hklout %TEMPRES%\toxd_nan.mtz < %SCRIPTWIN%\uniquefreeR.dat

::
:: E.g. (1)
::
:: Complete dataset and add free-R column.
:: Keep systematic absences with -s switch (though you probably wouldn't
:: want to do this).
::

::uniqueify -s %TEMPRES%\toxd_nan.mtz %TEMPRES%\toxd-unique.mtz

::
:: E.g. (2)
::
:: Complete dataset and add free-R column.
:: Increase the fraction of reflections tagged with each free-R
:: indicator above the default 0.05 (sensible for toxd which has
:: small dataset).
::

::uniqueify -p 0.1 %TEMPRES%\toxd_nan.mtz %TEMPRES%\toxd-unique2.mtz

::
:: E.g. (3)
::
:: First add free-R column to incomplete dataset.
:: (Silly thing to do - this is just to create a dataset with an existing
:: free-R column for illustrating use of uniqueify with -f switch.)
::

freerflag hklin %TEMPRES%\toxd_nan.mtz hklout %TEMPRES%\toxd_free.mtz < %SCRIPTWIN%\end.dat

::
:: Now complete with -f switch to indicate free-R column already present.
::

::uniqueify -f FreeR_flag %TEMPRES%\toxd_free.mtz %TEMPRES%\toxd-unique3.mtz
