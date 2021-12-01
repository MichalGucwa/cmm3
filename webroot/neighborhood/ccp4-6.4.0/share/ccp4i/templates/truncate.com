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
$SYMMETRY symmetry $SPACE_GROUP
$CELL cell $CELL_1 $CELL_2 $CELL_3 $CELL_4 $CELL_5 $CELL_6

1 truncate
 - { [StringSame $APPLY_TRUNCATE "WILSON" ] } YES | NO
{[IfSet $ANOMALOUS]} anomalous 
 - $ANOMALOUS YES | NO

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
1 plot
 - $WILSON_PLOT ON | OFF
1 header $OUTPUT_HEADER $OUTPUT_BATCH

IF { ![IfSet $INPUT_DATA] || ![StringSame $INPUT_DATA SCALA ] }
IF { ![StringSame $INPUT_DATA AMPLITUDES] }
  1 labin IMEAN=$IMEANIN SIGIMEAN=$SIGIMEANIN
    IF $ANOMALOUS
    - 1 I(+)=$Ipp I(-)=$Imm
    - 1 SIGI(+)=$SIGIpp SIGI(-)=$SIGImm
    ENDIF
ELSE
  1 labin F=$FMEANIN SIGF=$SIGFMEANIN
ENDIF
ENDIF

IF $USE_LABOUT
LABELLINE labout $LABOUT
ENDIF

1 falloff
- $FALLOFF yes | no
- {[IfSet $FALLOFF_CONE]} cone $FALLOFF_CONE
- {[IfSet $FALLOFF_PLOT]} $FALLOFF_PLOT

AT { [FileJoin [GetEnvPath CCP4I_TOP] templates harvest.com ] }

1 end

