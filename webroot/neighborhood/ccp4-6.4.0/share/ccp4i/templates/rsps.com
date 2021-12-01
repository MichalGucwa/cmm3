#
#     Copyright (C) 1999-2004  Liz Potterton, Peter Briggs
#
#     This code is distributed under the terms and conditions of the
#     CCP4 Program Suite Licence Agreement as a CCP4 Library.
#     A copy of the CCP4 licence can be obtained by writing to the
#     CCP4 Secretary, Daresbury Laboratory, Warrington WA4 4AD, UK.
#
#CCP4i_cvs_Id $Id$
#CCP4I SCRIPT TEMPLATE rsps

# Tell it what it ought to know
{ [IfSet $SPACE_GROUP ] } SPACEGROUP $SPACE_GROUP
$IFCELL CELL $CELL_1 $CELL_2 $CELL_3 $CELL_4 $CELL_5 $CELL_6

IF { $IFNCS && $NCS_NOPS > 0 } 
LOOP J 1 $NCS_NOPS
  1 ncsrot polar $NCS_OP_ALPHA($J) $NCS_OP_BETA($J) $NCS_OP_GAMMA($J)
  - 1 $NCS_OP_XTRAN($J) $NCS_OP_YTRAN($J) $NCS_OP_ZTRAN($J)
ENDLOOP
ENDIF

# Pick patterson
1 patfile \\"$PATFILE\\" type CCP4
1 pick patterson


#Harker scan of asymmetric unit
IF { [StringSame $RSPS_INPUT SCAN ] }
  1 scorfile \\"$HARKER_SCORFILE\\"
  1 vectorset single atoms
  { [IfSet $HARKER_LOW] } low $HARKER_LOW
  { [IfSet $HARKER_REJECT] } reject $HARKER_REJECT
  1 scan
    - $IFXYZLIM limits $XYZLIM_1 $XYZLIM_2 $XYZLIM_3 $XYZLIM_4 $XYZLIM_5 $XYZLIM_6 | au
#    - $IFGRID GRID $GRID_1 $GRID_2 $GRID_3

  1 pick scoremap $PICK_HARKER_N
  - { [IfSet $PICK_SCORMAP_LEVEL] } level $PICK_SCORMAP_LEVEL

  1 write positions \\"$HPEAKSFIL\\"
ENDIF

LOOP nf 1 $NINSITESFILE
  1 delete sets
  1 read \\"$INSITESFILE($nf)\\"

IF { $N_FIXED > 0 } 
  LOOP n 1 $N_FIXED
    1 delete fixxyz
    1 fixxyz site $FIXED_SITE($n)
  ENDLOOP
ENDIF

IF { [StringSame $RSPS_MODE GETSETS ] } 
  { [IfSet $GETSETS_LOW] } low $GETSETS_LOW
  { [IfSet $GETSETS_REJECT] } low $GETSETS_REJECT
  1 getsets $GETSETS_MIN $GETSETS_USE
  1 list sets
ENDIF

# Cross scan of top N_CROSS_PEAKS peaks

IF { [StringSame $RSPS_MODE CROSSPEAKS ] }
LOOP n 1 $N_CROSS_PEAKS
  1 scorfile $CROSS_SCORFILE($n)
  1 vectorset more atoms
  { [IfSet $CROSS_LOW] } low $CROSS_LOW
  { [IfSet $CROSS_REJECT] } low $CROSS_REJECT
  1 score $CROSS_SCAN_SCORE_MODE $CROSS_SCAN_SCORE_N
  1 fixxyz site $n
  1 scan
    - $IFXYZLIM limits $XYZLIM_1 $XYZLIM_2 $XYZLIM_3 $XYZLIM_4 $XYZLIM_5 $XYZLIM_6 | au

  1 pick scoremap $PICK_CROSS_N
  1 write positions \\"$XPEAKSFILS($n)\\"

  1 vectorset single atoms
  1 vlist site 1 $X_LIST_HARKER_N

ENDLOOP
ENDIF

ENDLOOP

1 exit
