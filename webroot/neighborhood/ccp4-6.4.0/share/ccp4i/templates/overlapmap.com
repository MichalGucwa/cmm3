#
#     Copyright (C) 1999-2004  Liz Potterton, Peter Briggs
#
#     This code is distributed under the terms and conditions of the
#     CCP4 Program Suite Licence Agreement as a CCP4 Library.
#     A copy of the CCP4 licence can be obtained by writing to the
#     CCP4 Secretary, Daresbury Laboratory, Warrington WA4 4AD, UK.
#
#CCP4i_cvs_Id $Id$
1 correlate $CORRELATE_MODE
$IF_REAL_SPACE real space R
LOOP n 1 $NCHAINS
{ [IfSet $CHAIN_NAME($n)] } chain $CHAIN_NAME($n) $CHAIN_RES1($n) $CHAIN_RES2($n) | chain "\" \"" $CHAIN_RES1($n) $CHAIN_RES2($n)
ENDLOOP
