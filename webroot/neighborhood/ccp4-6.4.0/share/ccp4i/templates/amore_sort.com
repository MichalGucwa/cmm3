#
#     Copyright (C) 1999-2004  Liz Potterton, Peter Briggs
#
#     This code is distributed under the terms and conditions of the
#     CCP4 Program Suite Licence Agreement as a CCP4 Library.
#     A copy of the CCP4 licence can be obtained by writing to the
#     CCP4 Secretary, Daresbury Laboratory, Warrington WA4 4AD, UK.
#
#CCP4i_cvs_Id $Id$
{[IfSet $TITLE]} title "$TITLE"
$VERBOSE verbose
1 sortfun 
- $SORTFUN_MODEL MODEL
- 1 resolution $RESOLUTION_MIN 
-- 1 $SORT_RESOLUTION_MAX
IF $SORTFUN_MODEL
LABELLINE labin "FC PHIC"
ELSE
LABELLINE labin "FP SIGFP"
ENDIF

