#
#     Copyright (C) 1999-2004  Liz Potterton, Peter Briggs
#
#     This code is distributed under the terms and conditions of the
#     CCP4 Program Suite Licence Agreement as a CCP4 Library.
#     A copy of the CCP4 licence can be obtained by writing to the
#     CCP4 Secretary, Daresbury Laboratory, Warrington WA4 4AD, UK.
#
#CCP4i_cvs_Id $Id: aimless.com,v 1.3 2012/05/16 09:22:25 ccb Exp $

{ [ IfSet $TITLE ] } title  $TITLE
# Overall resolution, possibly overridden by run resolutions
$EXCLUDE_RESOLUTION resolution 
 - $EXCLUDE_RESOLUTION_MIN low $EXCLUDE_RESOLUTION_MIN
 - $EXCLUDE_RESOLUTION_MAX high $EXCLUDE_RESOLUTION_MAX

IF { $RUN_SET == 1 }
# Explicit runs
#   run definitions
LOOP N 1  $NRUNS
 LOOP I 1  $RUN_DEFS($N)
  { [StringSame $RUN_MODE($N,$I) BATCHRANGE ] } run $N batch $RUN_IMIN($N,$I) to $RUN_IMAX($N,$I)
  { [StringSame $RUN_MODE($N,$I) RESOLUTION ] } resolution run $N low $RUN_RMIN($N,$I) high $RUN_RMAX($N,$I)
 ENDLOOP
ENDLOOP
ENDIF
# end run set

# Datasets out
$SET_PXDNAME name project $PNAME(1) crystal $XNAME(1) dataset $DNAME(1)

{!$REFINE } onlymerge

$REJECT_EMAX exclude $REJECT_EMAX 

IF { !$RUN_POINTLESS }
 # batch rejections, only if they have not been done in Pointless
 IF { $EXCLUDE_BATCH && $N_EXCLUDE_BATCH > 0 }
  LOOP I 1 $N_EXCLUDE_BATCH
   1 exclude batch 
   - { [StringSame $EXCLUDE_BATCH_DEFINE($I) LIST] } $EXCLUDE_BATCH_LIST($I)
   - { [StringSame $EXCLUDE_BATCH_DEFINE($I) RANGE] } $EXCLUDE_BATCH_FIRST($I) to $EXCLUDE_BATCH_LAST($I)
  ENDLOOP
 ENDIF
ENDIF

# partials acceptance flags
$IS_PARTIALS  partials
 - $IS_CHECK check | nocheck
 - $IS_TEST test $IS_TEST_MIN $IS_TEST_MAX
 - $IS_CORRECT correct $IS_CORRECT_LIMIT
 - $IS_GAP gap | nogap

# intensity selection  SUMMATION, PROFILE, COMBINE
$IS_SET  intensities $IS_MODE
 - $IS_COMBINE_IMIDSET $IS_COMBINE_IMID
 - $IS_COMBINE_POWERSET power $IS_COMBINE_POWER


# scales specification
LOOP N 1 $NSCALES
IF { ! [StringSame $SCALES_MODE($N)  DEFAULT]}

 $SCALES_SPEC($N) scales
  - { [ IfSet $SCALES_RUN($N)] }  $SCALES_RUN($N)

 CASE $SCALES_MODE($N)
 CASEMATCH CONSTANT
  - 1 $SCALES_MODE($N)
 CASEMATCH BATCH
  - 1 $SCALES_MODE($N)
 CASEMATCH ROTATION
  - 1 rotation $SCALES_ROTATION($N) $SCALES_ROTATION_ROT($N)
 CASEMATCH SECONDARY
  - 1 rotation $SCALES_ROTATION($N) $SCALES_ROTATION_ROT($N)
  - 1 secondary $SECONDARY_LMAX($N) 
 CASEMATCH ABSORPTION
  - 1 rotation $SCALES_ROTATION($N) $SCALES_ROTATION_ROT($N)
  - 1 absorption $SECONDARY_LMAX($N) 
  -- {[IfSet $SURFACE_POLE($N)]} pole $SURFACE_POLE($N)
 ENDCASE

  - 1 bfactor $SCALES_BFACTOR($N)
  -- { ![StringSame $SCALES_BFACTOR($N) OFF] && ![StringSame $SCALES_BROTATION($N) "NO_TIME" ] } $SCALES_BROTATION($N) $SCALES_BFACTOR_TIME($N)

ENDIF
ENDLOOP

# Ties
{ $TIE_ROTATION } tie rotation $TIE_ROTATION_SD
{ $TIE_SURFACE } tie surface $TIE_SURFACE_SD
{ $TIE_BFACTOR } tie bfactor $TIE_BFACTOR_SD
{ $TIE_ZEROB }   tie zerob   $TIE_ZEROB_SD

# Options for scale refinement
$REFINE_OPTIONS refine 
 - $CYCLES_FLAG $CYCLES
 - $SELECT $SELECT_IOVSDMIN
 - $SELECT2 $SELECT_EMIN

# Outlier rejection
$REJECT_SCALE reject scale 
 - $REJECT_COMBINE combine
 - { !$REJECT_COMBINE } separate
 - 1 $REJECT_SDMAX $REJECT_SDMAX2
$MERGE_REJECT reject merge
 - $MERGE_REJECT_COMBINE combine
 - { !$MERGE_REJECT_COMBINE } separate
 - 1 $MERGE_REJECT_SDMAX $MERGE_REJECT_SDMAX2
 - 1 all $MERGE_REJECT_ALL
$REJECT_EMAX reject emax $REJECT_EMAX_EMAX

# Anomalous
$ANOMALOUS_ON anomalous on 

# Output
$OUTPUT output
- 1 mtz $OUTPUT_TYPE_KEY
- { ![StringSame $OUTPUT_SCALEPACK_TYPE NONE] } scalepack $OUTPUT_SCALEPACK_TYPE_KEY
# SD correction
IF $SD_CORRECT
 1 sdcorrection 
 - $SD_REFINE  refine | norefine
 - 1 $SD_SAME
 - $SD_FIXSDB fixsdb
 - $SD_DAMP_SET damp $SD_DAMP
 - $SD_TIE_SDB tie SDB $SD_TIE_SDB_TARGET $SD_TIE_SDB_SD
ENDIF

IF $NSDS > 0
LOOP N 1 $NSDS
1 sdcorrection
 - { ![StringSame $SD_RUNS($N) ALL ] } run $SD_RUNS($N)
 - { ![StringSame $SD_APPLY($N) ALL ] } $SD_APPLY($N)
 - { [IfSet $SD_FAC($N) ] } $SD_FAC($N)
 -- { [IfSet $SD_B($N) ] } $SD_B($N) 
 -- 1 $SD_ADD($N)
ENDLOOP
ENDIF

IF { $ACCEPT_OVERLOADS || $ACCEPT_PKRATIO || $ACCEPT_BGGRADIENT || $ACCEPT_EDGE }
  1 keep
  - $ACCEPT_OVERLOADS overloads
  - $ACCEPT_PKRATIO pkratio $PKRATIO
  - $ACCEPT_BGGRADIENT gradient $BGGRADIENT
  - $ACCEPT_EDGE edge
ENDIF

AT { [FileJoin [GetEnvPath CCP4I_TOP] templates harvest.com ] }
