#
#     Copyright (C) 1999-2004  Liz Potterton, Peter Briggs
#
#     This code is distributed under the terms and conditions of the
#     CCP4 Program Suite Licence Agreement as a CCP4 Library.
#     A copy of the CCP4 licence can be obtained by writing to the
#     CCP4 Secretary, Daresbury Laboratory, Warrington WA4 4AD, UK.
#
#CCP4i_cvs_Id $Id$
##################################################
# FFFEAR: COMMAND SCRIPT
##################################################

1 SOLC $SOLC
- $USE_MEAN MEAN $SOLVVAL $PROTVAL
1 RESOLUTION $RESO_MIN $RESO_MAX

##################################################
# SEARCH parameters
##################################################

$USE_SEARCH SEARCH
- $USE_STEP   STEP  $SEARCH_STEP
- $USE_RANGE  RANGE $SEARCH_RANGE
- $USE_PEAKS  PEAKS $SEARCH_PEAKS

##################################################
# MTZ file labels
##################################################
LABELLINE labin "FP SIGFP PHIO FOMO"

##################################################
# CENTRE
##################################################

$USE_CENTRE CENTRE $FRC_OR_ORTH
- $USE_FRAC $FRAC_X $FRAC_Y $FRAC_Z
- $USE_ORTH $ORTH_X $ORTH_Y $ORTH_Z

##################################################
# MODEL
##################################################

1 MODEL RADIUS $MODEL_RADIUS
- $USE_MODEL_RESOL RESOLUTION $MODEL_RESOL
- { [IfSet $MODEL_BFAC] } BFACTOR $MODEL_BFAC
- $ROTATE_FRAG ROTATE $MODEL_ALPHA $MODEL_BETA $MODEL_GAMMA

##################################################
# SCALE
##################################################

IF { [StringSame $SCALE_TYPE USER] }
  1 SCALE $SCALE_SCALING $SCALE_BFAC
ELSE
  $SCALE_NATURAL SCALE NATURAL
ENDIF

##################################################
# MASK
##################################################

$USE_MASK MASK
- { [IfSet $MASK_RADIUS] } RADIUS $MASK_RADIUS

##################################################
# FILTER
##################################################

$APPLY_FILTER FILTER $FILTER_MAPMODEL
- $FILTER_VARIANCE VARIANCE
- 1 RADIUS $FILTER_RADIUS

##################################################
# END of script
##################################################

1 END


