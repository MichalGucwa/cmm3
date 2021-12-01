#
#     Copyright (C) 1999-2004  Liz Potterton, Peter Briggs
#
#     This code is distributed under the terms and conditions of the
#     CCP4 Program Suite Licence Agreement as a CCP4 Library.
#     A copy of the CCP4 licence can be obtained by writing to the
#     CCP4 Secretary, Daresbury Laboratory, Warrington WA4 4AD, UK.
#
#CCP4i_cvs_Id $Id$
1 symmetry $SPACE_GROUP
1 cell $CELL_1 $CELL_2 $CELL_3 $CELL_4 $CELL_5 $CELL_6
1 distance $DISTANCE
1 tolerance $TOLERANCE
IF { $USE_TIDY }
  1 tidy
  - { [StringSame $TIDY_MODE ORTH FRAC] } $TIDY_MODE $TIDY_X $TIDY_Y $TIDY_Z
ENDIF
{ [StringSame $OUTPUT_MODE ALL] } list
1 end
