#
#     Copyright (C) 1999-2004  Liz Potterton, Peter Briggs
#
#     This code is distributed under the terms and conditions of the
#     CCP4 Program Suite Licence Agreement as a CCP4 Library.
#     A copy of the CCP4 licence can be obtained by writing to the
#     CCP4 Secretary, Daresbury Laboratory, Warrington WA4 4AD, UK.
#
#CCP4i_cvs_Id $Id$
{ [IfSet $TITLE] } title  $TITLE
LOOP n 1 $N_BATCH
  1 batch 
- { [StringSame $BATCH_SELECT_MODE($n) RANGE ] }  $BATCH_RANGE_1($n) to $BATCH_RANGE_2($n) | all
  - 1 $BATCH_EDIT_MODE($n) $BATCH_NUMBER($n)
ENDLOOP
1 END
