#
#     Copyright (C) 1999-2004  Liz Potterton, Peter Briggs
#
#     This code is distributed under the terms and conditions of the
#     CCP4 Program Suite Licence Agreement as a CCP4 Library.
#     A copy of the CCP4 licence can be obtained by writing to the
#     CCP4 Secretary, Daresbury Laboratory, Warrington WA4 4AD, UK.
#
#CCP4i_cvs_Id $Id$
{[IfSet $TITLE]} title $TITLE
$VERBOSE verbose
1 trafun $TRAFUN_MODE NMOL $NMOL 
  - {[IfSet $RESOLUTION_MIN ]} resolution $RESOLUTION_MIN $RESOLUTION_MAX
  - {[IfSet $TRAFUN_NPIC ]} npic $TRAFUN_NPIC
  - {[IfSet $TRAFUN_PKLIM ]} pklim $TRAFUN_PKLIM
{[IfSet $CRYSTAL_ORTH]} crystal orth $CRYSTAL_ORTH
  - {[IfSet $CRYSTAL_FMIN ]} flim $CRYSTAL_FMIN $CRYSTAL_FMAX
  - {[IfSet $CRYSTAL_BADD ]} sharp $CRYSTAL_BADD
#  - {[IfSet $RESOLUTION_MIN ]} resolution $RESOLUTION_MIN $RESOLUTION_MAX
{[IfSet  $TEST_SPACE_GROUP]} symmetry $TEST_SPACE_GROUP

# SOLUTIONS are complete lines of data generated in the run script

1 $SOLUTIONS

$SHIFT shift 1
  - 1 com $MODEL_COM_1 $MODEL_COM_2 $MODEL_COM_3
  - 1 euler $MODEL_EULER_1 $MODEL_EULER_2 $MODEL_EULER_3

