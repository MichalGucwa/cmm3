::!/bin/sh -e
:: (Very) basic example for fsearch using rnase native
:: data and rnase coordinates as search model

fsearch HKLIN %RNASE%\rnase25.mtz XYZIN %RNASE%\rnase.pdb < %SCRIPTWIN%\fsearch.dat

