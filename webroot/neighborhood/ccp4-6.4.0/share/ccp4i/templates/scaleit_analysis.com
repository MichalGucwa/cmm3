#
#     Copyright (C) 1999-2004  Liz Potterton, Peter Briggs
#
#     This code is distributed under the terms and conditions of the
#     CCP4 Program Suite Licence Agreement as a CCP4 Library.
#     A copy of the CCP4 licence can be obtained by writing to the
#     CCP4 Secretary, Daresbury Laboratory, Warrington WA4 4AD, UK.
#
#CCP4i_cvs_Id $Id$
1 refine isotropic
$EXCLUDE_RESOLUTION resolution $EXCLUDE_RESOLUTION_MIN $EXCLUDE_RESOLUTION_MAX

$IFAUTO auto

LOOP N 1 $NEXCLUDE 
1 exclude
 - { ![StringSame $EXCLUDE_APPLY($N) "all" ] } $EXCLUDE_APPLY($N)
 - 1 $EXCLUDE_MODE($N)
 CASE $EXCLUDE_MODE($N)
 CASEMATCH SIG
   - 1 $EXCLUDE_SIGMAF($N)
 CASEMATCH FMAX
   - 1 $EXCLUDE_F($N)
 CASEMATCH DMAX
   - 1 $EXCLUDE_SIGMAD($N)
 CASEMATCH DIFF
   - 1 $EXCLUDE_DIF_FP($N)
 ENDCASE
ENDLOOP

LABELLINE LABIN $LABIN
