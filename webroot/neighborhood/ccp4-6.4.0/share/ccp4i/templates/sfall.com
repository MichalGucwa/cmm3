#
#     Copyright (C) 1999-2004  Liz Potterton, Peter Briggs
#
#     This code is distributed under the terms and conditions of the
#     CCP4 Program Suite Licence Agreement as a CCP4 Library.
#     A copy of the CCP4 licence can be obtained by writing to the
#     CCP4 Secretary, Daresbury Laboratory, Warrington WA4 4AD, UK.
#
#CCP4i_cvs_Id $Id$
{ [IfSet $TITLE ] } title $TITLE  

IF $SFALL_SFCALC_HKLIN
  LABELLINE LABIN $LABIN
IF { [IfSet $LABOUT] }
  1 labout
  LABELLINE - $LABOUT
ELSE
  $ALLIN labout ALLIN
ENDIF
ELSE
  LABELLINE labout $LABOUT
$HARVEST_INPUT_NAMES NAME 
  - { [IfSet $HARVEST_PNAME] } PROJECT $HARVEST_PNAME 
  - { [IfSet $HARVEST_XNAME] } CRYSTAL $HARVEST_XNAME 
  - { [IfSet $HARVEST_DNAME] } DATASET $HARVEST_DNAME
ENDIF

1 MODE $SFALL_MODE 
 - {[regexp SFCALC $SFALL_MODE]} $SFALL_SFCALC_IN  
 -- $SFALL_SFCALC_HKLIN HKLIN
 - {[regexp  ATMMAP $SFALL_MODE]} $SFALL_ATMMAP_MODE
{ $SFALL_SFCALC_HKLIN && !$SFALL_SFCALC_SCALE } noscale

$SFALL_RESOLUTION resolution $RESOLUTION_MIN
- { [IfSet $RESOLUTION_MAX] } $RESOLUTION_MAX
$IFCELL cell $CELL_1 $CELL_2 $CELL_3 $CELL_4 $CELL_5 $CELL_6
$GRID grid $GRID_1 $GRID_2 $GRID_3
{ [IfSet $SPACE_GROUP ] } symmetry $SPACE_GROUP
IF { [regexp ATMMAP $SFALL_MODE] && [regexp RESMOD $SFALL_ATMMAP_MODE] && $NCHAINS > 1 }
LOOP n 1 $NCHAINS
  1 chain $CHAIN_NAME($n) $CHAIN_RES1($n) $CHAIN_RES2($n)
ENDLOOP
ENDIF

ENDIF

{ [ IfSet $SFALL_BINS ] } bins $SFALL_BINS
{ [ IfSet $SFALL_BADD ] } badd $SFALL_BADD
{ [ IfSet $SFALL_VDWR ] } vdwr $SFALL_VDWR
$RSCB rscb $RSCB_MIN 
 - { [IfSet $RSCB_MAX] } $RSCB_MAX
1 end
