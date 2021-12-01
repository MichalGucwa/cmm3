#
#     Copyright (C) 1999-2004  Liz Potterton, Peter Briggs
#
#     This code is distributed under the terms and conditions of the
#     CCP4 Program Suite Licence Agreement as a CCP4 Library.
#     A copy of the CCP4 licence can be obtained by writing to the
#     CCP4 Secretary, Daresbury Laboratory, Warrington WA4 4AD, UK.
#
#CCP4i_cvs_Id $Id$
IF { $CHANGE_SPACE_GROUP }
  { [IfSet $SPACE_GROUP ] } symmetry $SPACE_GROUP
ENDIF
CASE $REINDEX_MODE
CASEMATCH HKL
1 reindex HKL $REINDEX_H, $REINDEX_K, $REINDEX_L
CASEMATCH AXIS
1 reindex AXIS $REINDEX_A, $REINDEX_B, $REINDEX_C
CASEMATCH MATCH
1 match $REINDEX_MATCH
ENDCASE
$IFLEFTHAND lefthand
{ !$IFREDUCE }  noreduce
1 end
