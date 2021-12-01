#
#     Copyright (C) 1999-2004  Liz Potterton, Peter Briggs
#
#     This code is distributed under the terms and conditions of the
#     CCP4 Program Suite Licence Agreement as a CCP4 Library.
#     A copy of the CCP4 licence can be obtained by writing to the
#     CCP4 Secretary, Daresbury Laboratory, Warrington WA4 4AD, UK.
#
#CCP4i_cvs_Id $Id$
{ [IfSet $TITLE] } title $TITLE

IF { [regexp FIT $SUPERPOSE_MODE  ] }
LOOP n 1 $N_MATCHS
CASE $FIT_SEL_MODE($n)
CASEMATCH ATOM
  1 fit atom $FIT_ATOML_1($n) to $FIT_ATOML_2($n) 
  - {[IfSet $FIT_CHAIN($n)]} chain $FIT_CHAIN($n)
  1 match $MATCH_ATOML_1($n) to $MATCH_ATOML_2($n) 
  -  {[IfSet $MATCH_CHAIN($n)]} chain $MATCH_CHAIN($n)
CASEMATCH RES
  1 fit res $RES_MODE($n) $FIT_RES_1($n) to $FIT_RES_2($n) 
  - {[IfSet $FIT_CHAIN($n)]} chain $FIT_CHAIN($n)
  1 match $MATCH_RES_1($n) to $MATCH_RES_2($n) 
  - {[IfSet $MATCH_CHAIN($n)] } chain $MATCH_CHAIN($n)
ENDCASE
ENDLOOP
ENDIF

IF { [regexp MOVE $SUPERPOSE_MODE  ] }
  {[IfSet $ROTATE_ALPHA]} rotate eulerian $ROTATE_ALPHA $ROTATE_BETA $ROTATE_GAMMA
  {[IfSet $TRANSLATE_X] } translate $TRANSLATE_X $TRANSLATE_Y $TRANSLATE_Z
ENDIF

1 output
- { $IFOUTPUTXYZ } xyz
- { $IFOUTPUTRMS } rms
- { $IFOUTPUTDELTAS } deltas

{ $IFRADIUS } radius $RADIUS_CUTOFF 
- { [regexp COORDS $SUPERPOSE_RADIUS_MODE] } $RADIUS_X $RADIUS_Y $RADIUS_Z

1 end
