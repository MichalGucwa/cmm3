#
#     Copyright (C) 1999-2004  Liz Potterton, Peter Briggs
#
#     This code is distributed under the terms and conditions of the
#     CCP4 Program Suite Licence Agreement as a CCP4 Library.
#     A copy of the CCP4 licence can be obtained by writing to the
#     CCP4 Secretary, Daresbury Laboratory, Warrington WA4 4AD, UK.
#
#CCP4i_cvs_Id $Id$
{ [IfSet $TITLE ] } title '$TITLE'

1 fiddlefactors $FACTOR_1 $FACTOR_2 
- $EXTRA_FIDDLE $FACTOR_3

{ [IfSet $SPACE_GROUP ] } symmetry $SPACE_GROUP
$CELL cell $CELL_1 $CELL_2 $CELL_3 $CELL_4 $CELL_5 $CELL_6

1 refine $REFINE_TYPE
$EXCLUDE_RESOLUTION  resolution $EXCLUDE_RESOLUTION_MAX $EXCLUDE_RESOLUTION_MIN

1 ranges
LOOP N 1 $NRANGES
  - 1 from $RES1($N) $CHAIN1($N) to $RES2($N) $CHAIN1($N)
ENDLOOP

LABELLINE labin $LABIN
