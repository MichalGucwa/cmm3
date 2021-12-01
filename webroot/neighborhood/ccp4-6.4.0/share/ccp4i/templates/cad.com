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
$OVERRIDE_SPACE_GROUP symmetry $SPACE_GROUP
$CELL cell $CELL_1 $CELL_2 $CELL_3 $CELL_4 $CELL_5 $CELL_6

$CENTRIC CENTRIC_ONLY
$SYSAB_KEEP SYSAB_KEEP
$EXCLUDE_RESOLUTION resolution overall $EXCLUDE_RESOLUTION_MIN $EXCLUDE_RESOLUTION_MAX
IF { [StringSame $OUTLIM_MODE SPACE_GROUP] }
  $HKL_LIMITS outlim spacegroup $OUTLIM_SPACE_GROUP
ELSE
  $HKL_LIMITS outlim hkllim $HKLLIM_1 $HKLLIM_2 $HKLLIM_3 $HKLLIM_4 $HKLLIM_5 $HKLLIM_6
ENDIF
$OVERRIDE_SORT_ORDER sort $SORT_ORDER

1 monitor $MONITOR
$REFMONITOR refmonitor $REFMONITOR

LOOP n 1 $NFILES
  1 labin file $n 
  IF { [StringSame $LABIN_MODE($n) ALL ] } 
    - 1 ALL
  ELSE
    LOOP k 1 $NLABIN($n)
    - $INCLUDE_COLUMN($n,$k) $E_LABEL($n,$k) =  $LABIN($n,$k)
    ENDLOOP
    1 labout file $n
    LOOP k 1 $NLABIN($n)
    - $INCLUDE_COLUMN($n,$k) $E_LABEL($n,$k) =  $LABOUT($n,$k)
    ENDLOOP
    1 ctypin file $n
    LOOP k 1 $NLABIN($n)
    - $INCLUDE_COLUMN($n,$k) $E_LABEL($n,$k) =  $CTYPIN($n,$k)
    ENDLOOP
  ENDIF
  $INPUT_SCALE($n) scale file $n  $INPUT_SCALE_FACTOR($n)
  $INPUT_RESOLUTION($n) resolution file $n $INPUT_RESOLUTION_MIN($n) $INPUT_RESOLUTION_MAX($n)
ENDLOOP
