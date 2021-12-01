#
#     Copyright (C) 1999-2004  Liz Potterton, Peter Briggs
#
#     This code is distributed under the terms and conditions of the
#     CCP4 Program Suite Licence Agreement as a CCP4 Library.
#     A copy of the CCP4 licence can be obtained by writing to the
#     CCP4 Secretary, Daresbury Laboratory, Warrington WA4 4AD, UK.
#

$CN_OR_DN POLAR $OMEGA $PHIA $KAPPA $OMEGA2 $PHI2 $KAPPA2 | POLAR $OMEGA $PHIA $KAPPA

1 ORTHO $ORTH_CONV

IF {[IfSet $INN_RAD] && $OMIT_INNER }
$SPH_OR_SLI SLICE $OUT_RAD $SLI_HEIGHT $INN_RAD | SPHERE $OUT_RAD $INN_RAD
ELSE
$SPH_OR_SLI SLICE $OUT_RAD $SLI_HEIGHT | SPHERE $OUT_RAD
ENDIF

1 OUTPUT XYZ MAP

1 REPORT $REP_REG $REP_TOP

1 END
