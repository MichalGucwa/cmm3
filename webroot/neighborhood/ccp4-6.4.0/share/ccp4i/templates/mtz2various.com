#
#     Copyright (C) 1999-2004  Liz Potterton, Peter Briggs
#
#     This code is distributed under the terms and conditions of the
#     CCP4 Program Suite Licence Agreement as a CCP4 Library.
#     A copy of the CCP4 licence can be obtained by writing to the
#     CCP4 Secretary, Daresbury Laboratory, Warrington WA4 4AD, UK.
#
#CCP4i_cvs_Id $Id$
1 OUTPUT $OUTPUT_FORMAT
 - { [StringSame $OUTPUT_FORMAT USER] } \"$USER_FORMAT\"
 - { [StringSame $OUTPUT_FORMAT CIF] } $CIF_DATA_NAME
LABELLINE labin $LABIN

$EXCLUDE_RESOLUTION resolution $EXCLUDE_RESOLUTION_MIN $EXCLUDE_RESOLUTION_MAX
$EXCLUDE_SIGP exclude sigp $EXCLUDE_SIGP_FACTOR
$EXCLUDE_SIGH exclude sigh $EXCLUDE_SIGH_FACTOR
$EXCLUDE_DIFF exclude diff $EXCLUDE_DIFF_LIMIT
$EXCLUDE_FPMAX exclude fpmax $EXCLUDE_FPMAX_MAX
$EXCLUDE_FPHMAX exclude fphmax $EXCLUDE_FPHMAX_MAX

$EXCLUDE_FREER free = $EXCLUDE_FREER_VALUE
$EXCLUDE_FREER excl free $EXCLUDE_FREER_VALUE
$FREER free = $FREER_VALUE

$FSQUARED fsquared scale $SCALE_FACTOR
$MISS miss $MISS_VALUE
$MONITOR monitor $MONITOR_NMON
1 end
