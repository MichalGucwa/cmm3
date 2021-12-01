#
#     Copyright (C) 1999-2004  Liz Potterton, Peter Briggs
#
#     This code is distributed under the terms and conditions of the
#     CCP4 Program Suite Licence Agreement as a CCP4 Library.
#     A copy of the CCP4 licence can be obtained by writing to the
#     CCP4 Secretary, Daresbury Laboratory, Warrington WA4 4AD, UK.
#
#CCP4i_cvs_Id $Id$
{ [IfSet $TITLE] } title $TITLE
$EXCLUDE_RESOLUTION resolution $EXCLUDE_RESOLUTION_MIN $EXCLUDE_RESOLUTION_MAX
CASE $TWIN_OP_MODE
CASEMATCH STD
{[IfSet $OPERATOR] } operator $OPERATOR
CASEMATCH HKL
1 operator $TWIN_H, $TWIN_K, $TWIN_L
ENDCASE
{ [IfSet $SIGMA] } sigma $SIGMA
$PLOT  PLOT MU
{ [StringSame $DETWIN_MODE DETWIN] && [IfSet $TWIN_FRACTION] } twin_fraction $TWIN_FRACTION
IF { [IfSet $LABIN] }
LABELLINE labin $LABIN
ENDIF
1 debug $DEBUG
1 end
