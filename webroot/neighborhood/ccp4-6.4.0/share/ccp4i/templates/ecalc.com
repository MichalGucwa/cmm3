#
#     Copyright (C) 1999-2004  Liz Potterton, Peter Briggs
#
#     This code is distributed under the terms and conditions of the
#     CCP4 Program Suite Licence Agreement as a CCP4 Library.
#     A copy of the CCP4 licence can be obtained by writing to the
#     CCP4 Secretary, Daresbury Laboratory, Warrington WA4 4AD, UK.
#
#CCP4i_cvs_Id $Id$
{ [IfSet $TITLE] } title  $TITLE

LABELLINE labin $LABIN
LABELLINE labout $LABOUT

{ [IfSet $SPACE_GROUP ] } spacegroup $SPACE_GROUP
$EXCLUDE_RESOLUTION resolution $EXCLUDE_RESOLUTION_MAX
$ECALC_EXCLUDE_CENTRIC exclude centric
{ [IfSet $ECALC_EXCLUDE_SIGP] } exclude sigp $ECALC_EXCLUDE_SIGP
{ [IfSet $ECALC_EXCLUDE_SIGPH] } exclude sigph $ECALC_EXCLUDE_SIGPH
{ [IfSet $ECALC_EXCLUDE_FPMAX] } exclude fpmax $ECALC_EXCLUDE_FPMAX
{ [IfSet $ECALC_EXCLUDE_FPHMAX] } exclude fphmax $ECALC_EXCLUDE_FPHMAX
{ [IfSet $ECALC_EXCLUDE_DIFF] } exclude diff $ECALC_EXCLUDE_DIFF

{ [IfSet $SHELL] } shell $SHELL
{ [IfSet $SCALE] } scale $SCALE

$MULTAN multan
$SNB snb
{ ($MULTAN || $SNB) && [IfSet $REFLECTIONS ] } reflections $REFLECTIONS
