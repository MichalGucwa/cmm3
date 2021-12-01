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

1 fitfun 
- 1 nmol $NMOL
- 1 resolution $RESOLUTION_MIN $RESOLUTION_MAX
- {[IfSet $FITFUN_NITER]}  iter $FITFUN_NITER
- {[IfSet $FITFUN_CONV]}  conv $FITFUN_CONV

#1 crystal orth $CRYSTAL_ORTH
#  - 1 flim $CRYSTAL_FMIN $CRYSTAL_FMAX
#  - 1 sharp $CRYSTAL_BADD
#  - 1 resolution $RESOLUTION_MIN $RESOLUTION_MAX

{[IfSet $TEST_SPACE_GROUP]}  symmetry $TEST_SPACE_GROUP
1 refsolution $REFSOLUTION

1 $SOLUTIONS

IF $SHIFT
LOOP nm 1 $NMODELS
1 shift 1
  - 1 com $COM_1($nm) $COM_2($nm) $COM_3($nm)
  - 1 euler $EULER_1($nm) $EULER_2($nm) $EULER_3($nm)
ENDLOOP
ENDIF


