#
#     Copyright (C) 1999-2004  Liz Potterton, Peter Briggs
#
#     This code is distributed under the terms and conditions of the
#     CCP4 Program Suite Licence Agreement as a CCP4 Library.
#     A copy of the CCP4 licence can be obtained by writing to the
#     CCP4 Secretary, Daresbury Laboratory, Warrington WA4 4AD, UK.
#
#CCP4i_cvs_Id $Id$
1 TITLE $MAP_TITLE $AXIS = $FIRST_SECTION to $LAST_SECTION
1 MAP 
- {[IfSet $NPO_SCALE]} SCALE $NPO_SCALE

1 CONTOURS
 - $PLOT_NEG NEG
 - 1 $CONTOUR_PARAM
IF  { [ StringSame $CONTOUR_MODE "CONTOUR_LIST" ] } 
 - 1 $CONTOUR_LIST_1 $CONTOUR_LIST_2 $CONTOUR_LIST_3
 - 1 $CONTOUR_LIST_4 $CONTOUR_LIST_5 $CONTOUR_LIST_6
ELSE
 - 1 $CONTOUR_RANGE_1 TO $CONTOUR_RANGE_2 BY $CONTOUR_RANGE_STEP
ENDIF

1 sections 
 - $SECTION_FRAC frac 
 - 1 $FIRST_SECTION $LAST_SECTION $SKIP_SECTIONS
$GRID_PLOT_MODE GRID $NPO_GRID_1 $NPO_GRID_2 $NPO_GRID_3 $NPO_GRID_4

IF { ![StringSame $COORDS_MODE "NO" ] } 

  1 INPUT PDB

  CASE $NPO_LABELS 
  CASEMATCH NUMBER
    LOOP na 1 $NATOMS
      1 LABEL TEXT $na $ATOM($na) 1 1
    ENDLOOP
  CASEMATCH LABEL
    1 LABEL ALL
  ENDCASE

  1 SOLID NOHID
  1 RADII ATOMS X 1.2 VCC 1.2
  1 VIEW $AXIS
  1 MONO
  1 COLOUR BLACK

ENDIF

1 SIZE 0 CHAR $NPO_CHAR_SIZE

1 PLOT
1 END
