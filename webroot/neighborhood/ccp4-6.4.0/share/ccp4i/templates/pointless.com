#
#     Copyright (C) 2007  Phil Evans, Peter Briggs
#
#     This code is distributed under the terms and conditions of the
#     CCP4 Program Suite Licence Agreement as a CCP4 Library.
#     A copy of the CCP4 licence can be obtained by writing to the
#     CCP4 Secretary, Daresbury Laboratory, Warrington WA4 4AD, UK.
#
#CCP4i_cvs_Id $Id$
#CCP4I SCRIPT TEMPLATE pointless

# Template for pointless

# Cell if set (must precede HKLIN etc)
$SHOW_CELL CELL $CELL_1 $CELL_2 $CELL_3 $CELL_4 $CELL_5 $CELL_6

# All filenames are templates
$TEMPLATE_FILENAMES WILDFILE

# Loop over input files
LOOP N 1 $N_HKLINX
  IF { $N == 1 }
    # Base dataset definition
    $SET_PXDNAME NAME PROJECT $PNAME($N) CRYSTAL $XNAME($N) DATASET $DNAME($N)
  ELSE
    # Subsequent reassignments are optional
    { ! $USE_PREV_DATASET($N) } NAME PROJECT $PNAME($N) CRYSTAL $XNAME($N) DATASET $DNAME($N)
  ENDIF
  { [StringSame $HKLIN_FILETYPE "MTZ"] } HKLIN $HKLINX($N)
  { [StringSame $HKLIN_FILETYPE "XDS"] } XDSIN $XDS_SCA_IN($N)
  { [StringSame $HKLIN_FILETYPE "SCA"] } SCAIN $XDS_SCA_IN($N)
ENDLOOP

# TESTFIRSTFILE & ASSUMESAMEINDEXING options for multiple inputs only
IF { $N_HKLINX > 1 }
  # TESTFIRSTFILE off by default
  $TESTFIRSTFILE TESTFIRSTFILE
  # ASSUMESAMEINDEXING OFF by default unless wild-cards are used
  IF { $ASSUMESAMEINDEXINGSET }
    $ASSUMESAMEINDEXING ASSUMESAMEINDEXING ON |  ASSUMESAMEINDEXING OFF
  ENDIF
ENDIF

# Labels for merged test data
$MERGED_DATA LABIN F=$F_IN

# Use reference file if specified (HKLREF or XYZIN), with labels if merged MTZ
IF {$USE_HKLREF}
  IF {$USE_XYZIN} 
#  XYZIN
      1 XYZIN $XYZIN
  ELSE
    1 HKLREF $HKLREF
    IF {$MERGED_REF }
      LABREF F=$F_REF
    ENDIF
  ENDIF
ENDIF

# Set output file
$WRITE_HKLOUT HKLOUT $HKLOUT

# EXCLUDE BATCH
IF { $EXCLUDE_BATCH && $N_EXCLUDE_BATCH > 0 }
LOOP I 1 $N_EXCLUDE_BATCH
 1 exclude 
 - { $EXCLUDE_BATCH_SERIES($I) > 0 } series $EXCLUDE_BATCH_SERIES($I)
 - { [StringSame $EXCLUDE_BATCH_DEFINE($I) LIST] } batch $EXCLUDE_BATCH_LIST($I)
 - { [StringSame $EXCLUDE_BATCH_DEFINE($I) RANGE] } batch $EXCLUDE_BATCH_FIRST($I) to $EXCLUDE_BATCH_LAST($I)
ENDLOOP
ENDIF

# COPY option
$COPY COPY

# Setting
IF { $SET_SETTING }
   CASE $SETTING_CHOICE
   CASEMATCH "CELL-BASED"
      1 SETTING CELL-BASED
   CASEMATCH "SYMMETRY-BASED"
      1 SETTING SYMMETRY-BASED
   CASEMATCH "C2"
      1 SETTING C2
   ENDCASE
ENDIF

# PARTIALS available in all modes
IF { $PARTIALS_NOCHECK || $PARTIALS_TEST || $PARTIALS_CORRECT || $PARTIALS_GAP }
   1 PARTIALS
   - { $PARTIALS_NOCHECK } NOCHECK
   - { $PARTIALS_TEST } TEST $PARTIALS_LOWER $PARTIALS_UPPER
   - { $PARTIALS_CORRECT } CORRECT $PARTIALS_MINIMUM
   - { $PARTIALS_GAP } GAP $PARTIALS_GAP_LIMIT
ENDIF

# RESOLUTION/ISIGLIMIT available in all modes
IF { $USE_RESOL_CUTOFF }
CASE $RESOL_CUTOFF_MODE
CASEMATCH "RESOLUTION"
   { [IfSet $RESMIN] || [IfSet $RESMAX] } RESOLUTION
   - { [IfSet $RESMIN] } LOW $RESMIN
   - { [IfSet $RESMAX] } HIGH $RESMAX
CASEMATCH "ISIGLIMIT"
   { [IfSet $ISIGLIMIT] } ISIGLIMIT $ISIGLIMIT
ENDCASE
ENDIF

IF { [StringSame $LATTICE_MODE "CELL"] }
   $USE_TOLERANCE TOLERANCE $LATTICE_TOLERANCE
ENDIF

IF { [StringSame $LATTICE_MODE "ORIGINALLATTICE"] }
   1 ORIGINALLATTICE
ENDIF

$NEIGHBOUR  neighbour $NEIGHBOUR_FRACTION

IF {$CHOOSE}
 IF {$CHOOSE_SOLUTION}
# Choice of solutions
   CASE $CHOOSE_TYPE
   CASEMATCH "SOLUTION_NUMBER"
	1 choose solution $CHOOSE_NUMBER
   CASEMATCH "LAUE_GROUP"
	1 choose lauegroup $CHOOSE_GROUP
   CASEMATCH "SPACE_GROUP"
	1 choose spacegroup $CHOOSE_GROUP
   ENDCASE
  ELSE
#  Specify solution: these are alternatives
   $SPECIFY_LAUEGROUP  lauegroup $SPECIFY_GROUP
   $SPECIFY_SPACEGROUP spacegroup $SPECIFY_GROUP
ENDIF

$REINDEX  reindex  $REINDEX_H,  $REINDEX_K,  $REINDEX_L


1 END
# Done
