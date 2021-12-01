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

$RESOLUTION resolution $RESOLUTION_MIN $RESOLUTION_MAX
$BINS shells $N_BINS
$LIST list $LIST_N_REF
$USE_SDS bias 1 | bias 0
$CENTRIC CENTRIC
$IFAUTO AUTO

LABELLINE LABIN $LABIN_FP
LOOP N 1 $N_DERIVS
  LABELLINE - $LABIN_FPH $N
IF $ANOMALOUS_DATA
  LABELLINE - $LABIN_DPH $N
ENDIF
ENDLOOP
