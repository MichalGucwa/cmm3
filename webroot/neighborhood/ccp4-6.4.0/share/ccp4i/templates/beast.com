#
#     Copyright (C) 1999-2004  Liz Potterton, Peter Briggs
#
#     This code is distributed under the terms and conditions of the
#     CCP4 Program Suite Licence Agreement as a CCP4 Library.
#     A copy of the CCP4 licence can be obtained by writing to the
#     CCP4 Secretary, Daresbury Laboratory, Warrington WA4 4AD, UK.
#
#CCP4i_cvs_Id $Id$
{ [ IfSet $TITLE ] } #title $TITLE

LABELLINE LABIN $LABIN

LOOP NMOL 1 $NMOLECULES
1 MOLECULE $MOLECULE_ID($NMOL) $MOLECULE_FRACTION($NMOL)
LOOP NMOD 1 $NMODELS($NMOL)
1 MODEL $MOLECULE_ID($NMOL) \\"$XYZIN($NMOL,$NMOD)\\"
- {[StringSame $ERROR_MODE($NMOL,$NMOD) IDENT]} IDENT $ERROR_IDENT($NMOL,$NMOD)
- {[StringSame $ERROR_MODE($NMOL,$NMOD) RMS  ]} RMS   $ERROR_RMS($NMOL,$NMOD)
ENDLOOP
ENDLOOP

IF {[StringSame $MR_MODE SEARCH]}
  1 SEARCH $MOLECULE_MR 
  CASE $ROTATE_OPTIONS
  CASEMATCH NONE
  - 1 ROTATE 0.0 0.0 0.0 
  CASEMATCH FULL
  - 1 ROTATE FULL $ROTATE_STEP_SIZE
  CASEMATCH REGION
  - 1 ROTATE REGION 
  -- 1 $ROTATE_REGION_ALPHA1 $ROTATE_REGION_ALPHA2
  -- 1 $ROTATE_REGION_BETA1 $ROTATE_REGION_BETA2
  -- 1 $ROTATE_REGION_GAMMA1 $ROTATE_REGION_GAMMA2
  -- 1 $ROTATE_STEP_SIZE
  CASEMATCH AROUND
  - 1 ROTATE AROUND LIST $ROTATE_AROUND_RADIUS
  -- { [IfSet $ROTATE_AROUND_STEPSIZE] } $ROTATE_AROUND_STEPSIZE
  CASEMATCH RLIST
  - 1 ROTATE LIST
  ENDCASE

  CASE $TRANSLATE_OPTIONS
  CASEMATCH NONE
  CASEMATCH AROUND
  - 1 TRANSLATE AROUND LIST $TRANSLATE_AROUND_RADIUS
  -- { [IfSet $TRANSLATE_AROUND_STEPSIZE] } $TRANSLATE_AROUND_STEPSIZE
  CASEMATCH TLIST
  - 1 TRANSLATE LIST  
  CASEMATCH REGION
     CASE $TRANSLATE_GRID
     CASEMATCH HCP
     - 1 TRANSLATE REGION 
     -- 1 $TRANSLATE_REGION_X1 $TRANSLATE_REGION_X2
     -- 1 $TRANSLATE_REGION_Y1 $TRANSLATE_REGION_Y2
     -- 1 $TRANSLATE_REGION_Z1 $TRANSLATE_REGION_Z2
     -- { [IfSet $TRANSLATE_REGION_STEP] } $TRANSLATE_REGION_STEP
     CASEMATCH FRACTIONAL
     - 1 TRANSLATE FRACTIONAL
     -- 1 $TRANSLATE_REGION_X1 $TRANSLATE_REGION_X2 $TRANSLATE_REGION_XSTEP
     -- 1 $TRANSLATE_REGION_Y1 $TRANSLATE_REGION_Y2 $TRANSLATE_REGION_YSTEP
     -- 1 $TRANSLATE_REGION_Z1 $TRANSLATE_REGION_Z2 $TRANSLATE_REGION_ZSTEP
     ENDCASE
  ENDCASE

  IF { [StringSame $ROTATE_OPTIONS RLIST AROUND] && [StringSame $EULER_ENTRY MANUAL BOTH] }
    LOOP N 1 $NEULER
    1 RLIST $MOLECULE_MR $ALPHA($N) $BETA($N) $GAMMA($N)
    ENDLOOP 
  ENDIF 

  IF { [StringSame $ROTATE_OPTIONS RLIST AROUND] && [StringSame $EULER_ENTRY FILE BOTH] }
    1 @$MR_FILE
  ENDIF

  IF { [StringSame $TRANSLATE_OPTIONS TLIST AROUND] }
    LOOP N 1 $NVECTOR
    1 TLIST $MOLECULE_MR $X1($N) $Y1($N) $Z1($N)
    ENDLOOP
  ENDIF  

ENDIF

IF {[StringSame $MR_MODE TRIAL]}
  1 SEARCH $MOLECULE_MR
  CASE $TRIAL_TYPE
  CASEMATCH ROT
    LOOP N 1 $NTRIAL
    1 TRIAL $MOLECULE_MR $TRIAL_ALPHA($N) $TRIAL_BETA($N) $TRIAL_GAMMA($N)
    ENDLOOP
  CASEMATCH ROTTRANS
    LOOP N 1 $NTRIAL
    1 TRIAL $MOLECULE_MR $TRIAL_ALPHA($N) $TRIAL_BETA($N) $TRIAL_GAMMA($N)
    -- 1 $TRIAL_X($N) $TRIAL_Y($N) $TRIAL_Z($N)
    ENDLOOP
  CASEMATCH MRFILE
    1 @$MR_FILE
  ENDCASE
ENDIF

IF { $FIX && $NFIX_ORIENT > 0 }
  LOOP N 1 $NFIX_ORIENT
  1 FIX $MOLECULE_FIX_ORIENT($N)
  - 1 $FIX_ORIENT_ALPHA($N) $FIX_ORIENT_BETA($N) $FIX_ORIENT_GAMMA($N)
  - { [StringSame $FIX_MODE($N) ORIENTPOSITION] } $FIX_ORIENT_X($N) $FIX_ORIENT_Y($N) $FIX_ORIENT_Z($N)
  ENDLOOP
ENDIF

$TOG_RESOLUTION_LIMITS RESOLUTION $DMIN
  - { [IfSet $DMAX] } $DMAX
IF { $TOG_NBEST }
  1 BEST $NBEST
  - { [IfSet $NBESTT] } $NBESTT
ELSE
  $TOG_NBESTT BEST 20 $NBESTT
ENDIF
IF { !$TOG_NO_MR_BEST_FILE } 
  1 BEST FILE \\"$MR_BEST_FILE\\"
ENDIF
$TOG_NCLUST CLUSTER $NCLUST
IF { !$TOG_NO_MR_CLUST_FILE }
  1 CLUST FILE \\"$MR_CLUST_FILE\\"
ENDIF
$TOG_AVERAGE AVERAGE $AVERAGE
IF { $TOG_PIVOT_POINT && [StringSame $PIVOT_POINT CENTRE] } 
  1 PIVOT CENTRE 
ENDIF
IF { $TOG_PIVOT_POINT && [StringSame $PIVOT_POINT VECTOR] } 
  1 PIVOT $PIVOT_X $PIVOT_Y $PIVOT_Z
ENDIF
$TOG_SOL SOLPAR $FSOL $BSOL
$TOG_OUTLIER OUTLIER $OUTLIER
$TOG_SHANNON SHANFAC $SHANNON
$TOG_BOXSCALE BOXSCALE $BOXSCALE
$TOG_REPORT REPORT $REPORT
$TOG_VERBOSE VERBOSE
