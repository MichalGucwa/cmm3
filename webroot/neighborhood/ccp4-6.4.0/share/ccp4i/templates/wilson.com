#
#     Copyright (C) 1999-2004  Liz Potterton, Peter Briggs
#
#     This code is distributed under the terms and conditions of the
#     CCP4 Program Suite Licence Agreement as a CCP4 Library.
#     A copy of the CCP4 licence can be obtained by writing to the
#     CCP4 Secretary, Daresbury Laboratory, Warrington WA4 4AD, UK.
#
#CCP4i_cvs_Id $Id$
{ [ IfSet $TITLE ] } title  $TITLE
LABELLINE labin $LABIN
$SYMMETRY symmetry $SPACE_GROUP
$CELL cell $CELL_1 $CELL_2 $CELL_3 $CELL_4 $CELL_5 $CELL_6

CASE $RANGE_MODE
CASEMATCH NUMBER
  1 ranges $RANGE_NUMBER
CASEMATCH WIDTH
  1 ranges $RANGE_WIDTH
ENDCASE

$EXCLUDE_RESOLUTION resolution $EXCLUDE_RESOLUTION_MIN $EXCLUDE_RESOLUTION_MAX
$SCALE_RESOLUTION rscale $SCALE_RESOLUTION_MIN $SCALE_RESOLUTION_MAX

IF { [StringSame $CONTENTS_MODE "NRES" ] }
  {[IfSet $CONTENTS_NRES]}  nresidue $CONTENTS_NRES
ELSE
  1 contents
  LOOP N 1 $N_CONTENTS
    - { [ IfSet $CONTENTS_ATOM_TYPE($N) ] } $CONTENTS_ATOM_TYPE($N) $CONTENTS_ATOM_COUNT($N)
  ENDLOOP
ENDIF

$CONTENTS_USE_VPAT vpat $CONTENTS_VPAT

1 end

