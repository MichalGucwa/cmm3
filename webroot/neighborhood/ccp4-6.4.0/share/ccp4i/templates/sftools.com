#
#     Copyright (C) 1999-2004  Liz Potterton, Peter Briggs
#
#     This code is distributed under the terms and conditions of the
#     CCP4 Program Suite Licence Agreement as a CCP4 Library.
#     A copy of the CCP4 licence can be obtained by writing to the
#     CCP4 Secretary, Daresbury Laboratory, Warrington WA4 4AD, UK.
#
#CCP4i_cvs_Id $Id$
##################################################
# SFTOOLS: COMMAND SCRIPT
##################################################

1 mode batch

##################################################
# Must always read in with requested format
##################################################

IF { [StringSame $FORMAT_IN MTZ] }
  1 read \\\"$HKLIN\\\" mtz
ELSE
  1 read \\\"$HKLIN\\\" $FORMAT_IN
  IF { [StringSame $FORMAT_IN XPL TNT 31] }
    1 $CELL_A $CELL_B $CELL_C $CELL_ALPHA $CELL_BETA $CELL_GAMMA
    1 $NEW_SPACEGROUP
    1 end
  ENDIF
ENDIF


##################################################
# Apply Selection
##################################################

IF { $APPLY_SELECT }

  1 select none
  LOOP n 1 $N_SELECT_CRITERIA
    1 select $SELECT_MODE($n)
    CASE $SELECT_CRITERIA($n)
    CASEMATCH ALL
      - 1 all
    CASEMATCH COL
      - 1 col \\\"$SELECT_COL_1($n)\\\" $SELECT_COL_OP($n) $SELECT_COL_VAL($n)
    CASEMATCH COMPARE
      - 1 col \\\"$SELECT_COL_1($n)\\\" $SELECT_COMPARE_OP($n) \\\"$SELECT_COL_2($n)\\\"
    CASEMATCH RESO
      - {[regexp MIN $SELECT_RESO_MODE($n)]} resol <= $SELECT_RESO_MIN($n) | resol >= $SELECT_RESO_MAX($n)
    CASEMATCH INDEX
      - 1 index  $SELECT_INDEX_H($n) $SELECT_INDEX_K($n) $SELECT_INDEX_L($n) $SELECT_INDEX_OP($n) $SELECT_INDEX_SUM($n)
    CASEMATCH MULTI
      - 1 multi $SELECT_N_FOLD($n)
    CASEMATCH PRESENT
      - 1 col \\\"$SELECT_COL_1($n)\\\" present
    CASEMATCH MISSING
      - 1 col \\\"$SELECT_COL_1($n)\\\" absent
    ENDCASE
  ENDLOOP
ENDIF

##################################################
# Action = reduce to the asymmetric unit
##################################################

IF { [StringSame $SF_ACTION REDUCE] }

  IF { [StringSame $ASYM_UNIT MATRIX] }
    1 reduce MATRIX $I_1 $I_2 $I_3 $I_4 $I_5 $I_6 $I_7 $I_8 $I_9
  ELSE
    1 reduce $ASYM_UNIT
  ENDIF

ENDIF


##################################################
# Action = Sort
##################################################

IF { [StringSame $SF_ACTION SORT] }

  IF { [StringSame $SORT_ON HKL] }
    1 sort $SORT_INDICES $DIRECTION
  ENDIF

  IF { [StringSame $SORT_ON RESOL] }  
    1 sort RESOL $DIRECTION
  ENDIF

  IF { [StringSame $SORT_ON COL] }
    IF { [StringSame $FORMAT_IN MTZ] }
      1 sort COL \\\"$SORT_LABEL\\\" $DIRECTION
    ELSE
      1 sort COL \\\"$SORT_COL\\\" $DIRECTION
    ENDIF
  ENDIF

ENDIF

##################################################
# Action = expand to lower symmetry
##################################################

IF { [StringSame $SF_ACTION EXPAND] }
  IF { [StringSame $ASYM_UNIT MATRIX] }
    1 expand $EXPAND_SPACEGP_NUM MATRIX $I_1 $I_2 $I_3 $I_4 $I_5 $I_6 $I_7 $I_8 $I_9
  ELSE
    1 expand $EXPAND_SPACEGP_NUM $ASYM_UNIT
  ENDIF
ENDIF


##################################################
# Action = reindex reflections
##################################################

IF { [StringSame $SF_ACTION REINDEX] }
  1 reindex MATRIX $I_1 $I_2 $I_3 $I_4 $I_5 $I_6 $I_7 $I_8 $I_9
  1 Y
ENDIF


##################################################
# Action = merge reflections
##################################################

IF { [StringSame $SF_ACTION MERGE] }
  1 merge $MERGE_MODE
ENDIF


##################################################
# Action = purge (delete) selected reflections
##################################################

IF { [StringSame $SF_ACTION PURGE] }

  { [StringSame $PURGE_MODE DELETE] } select invert
  1 purge
  1 Y

ENDIF

##################################################
# Action = set new header information
##################################################

IF { [StringSame $SF_ACTION SET] }

  IF { $NTITLES > 0 } 
    1 set title
    LOOP N 1 $NTITLES
      1 $TITLE_CARD($N)
    ENDLOOP
    1 end
  ENDIF

  IF { $SET_NEW_CELL }
    LOOP n 1 $N_XNAME
      1 set dcell
      1 $DCELL_1($n) $DCELL_2($n) $DCELL_3($n) $DCELL_4($n) $DCELL_5($n) $DCELL_6($n) $XNAME($n)
    ENDLOOP
    1 set spacegroup
    1 $NEW_SPACEGROUP
  ENDIF

  IF { $SET_NEW_WAVE }
    LOOP n 1 $N_DNAME
      1 set dwave
      1 $DWAVE($n) $XNAME($n) $DNAME($n)
    ENDLOOP
  ENDIF

  LOOP N 1 $NLABIN
    1 set types col \\\"$LABIN($N)\\\"
    1 $CTYPIN($N)
    1 set labels col \\\"$LABIN($N)\\\"
    1 \\\"$LABOUT($N)\\\"
  ENDLOOP

ENDIF


##################################################
# Action = delete columns
##################################################

IF { [StringSame $SF_ACTION DELETE] }
  LOOP N 1 $NCOLS_DEL
    1 delete column \\\"$DEL_MTZ_LABEL($N)\\\"
  ENDLOOP
ENDIF


##################################################
# Action = generate Hendrickson-Lattman coefficients
##################################################

IF { [StringSame $SF_ACTION HLCONV ]}
  1 hlconv col $HL_MTZ_PHASE $HL_MTZ_FOM
ENDIF

########################################################################
#  List selected reflections
########################################################################

IF { [StringSame $SF_ACTION LIST] }
1 list ref col 
 - {![regexp Unassigned $LIST_COL_1 ]} $LIST_COL_1
 - {![regexp Unassigned $LIST_COL_2 ]} $LIST_COL_2
 - {![regexp Unassigned $LIST_COL_3 ]} $LIST_COL_3
 - {![regexp Unassigned $LIST_COL_4 ]} $LIST_COL_4
 - {![regexp Unassigned $LIST_COL_5 ]} $LIST_COL_5
 - {![regexp Unassigned $LIST_COL_6 ]} $LIST_COL_6
ENDIF


##################################################
# Finally, write out in required format:
##################################################

 { !$$APPLY_SELECT }  select all
 1 write \\\"$HKLOUT\\\" mtz


1 EXIT
1 YES

