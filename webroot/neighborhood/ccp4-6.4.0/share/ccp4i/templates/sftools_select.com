#
#     Copyright (C) 1999-2004  Liz Potterton, Peter Briggs
#
#     This code is distributed under the terms and conditions of the
#     CCP4 Program Suite Licence Agreement as a CCP4 Library.
#     A copy of the CCP4 licence can be obtained by writing to the
#     CCP4 Secretary, Daresbury Laboratory, Warrington WA4 4AD, UK.
#
#CCP4i_cvs_Id $Id$
1 select none
LOOP n 1 $N_SELECT_CRITERIA
  1 select $SELECT_MODE($n)
  CASE $SELECT_CRITERIA($n)
  CASEMATCH ALL
    - 1 all
  CASEMATCH COL
    - 1 col $SELECT_COL_1($n) $SELECT_COL_OP($n) $SELECT_COL_VAL($n)
  CASEMATCH COMPARE
    - 1 col $SELECT_COL_1($n) $SELECT_COMPARE_OP($n) $SELECT_COL_2($n)
  CASEMATCH RESO
    - {[regexp MIN $SELECT_RESO_MODE($n)]} resol <= $SELECT_RESO_MIN($n) | resol >= $SELECT_RESO_MAX($n)
  CASEMATCH INDEX
    - 1 index  $SELECT_INDEX_H($n) $SELECT_INDEX_K($n) $SELECT_INDEX_L($n) $SELECT_INDEX_OP($n) $SELECT_INDEX_SUM($n)
  CASEMATCH MULTI
    - multi $SELECT_N_FOLD($n)
  CASEMATCH PRESENT
    - col $SELECT_COL_1($n) present
  CASEMATCH ABSENT
    - col $SELECT_COL_1($n) absent
  ENDCASE
ENDLOOP

