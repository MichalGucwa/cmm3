#
#     Copyright (C) 1999-2004  Liz Potterton, Peter Briggs
#
#     This code is distributed under the terms and conditions of the
#     CCP4 Program Suite Licence Agreement as a CCP4 Library.
#     A copy of the CCP4 licence can be obtained by writing to the
#     CCP4 Secretary, Daresbury Laboratory, Warrington WA4 4AD, UK.
#
#CCP4i_cvs_Id $Id$
{ [ IfSet $TITLE ] } title $TITLE
LABELLINE labin $LABIN
LABELLINE labout $LABOUT

1 ranges $RANGES_NBIN 
 - { [ IfSet $RANGES_MON ] } $RANGES_MON
$SIGMAA_ERROR error
$SIGMAA_RESOLUTION resolution $RESOLUTION_MAX
  - 1 $RESOLUTION_MIN
{ [ IfSet $SIGMAA_SPACE_GROUP ] } symmetry $SIGMAA_SPACE_GROUP
$COMBINE_PART combine part 
 - 1 $COMBINE_PART 
 - {[IfSet $SIGMAA_DAMP]} damp $SIGMAA_DAMP
$COMBINE_MIR combine mir2 
$PART partial 
 - {[IfSet $SIGMAA_DAMP]} damp $SIGMAA_DAMP
1 end
