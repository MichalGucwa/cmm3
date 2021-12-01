#
#     Copyright (C) 1999-2004  Liz Potterton, Peter Briggs
#
#     This code is distributed under the terms and conditions of the
#     CCP4 Program Suite Licence Agreement as a CCP4 Library.
#     A copy of the CCP4 licence can be obtained by writing to the
#     CCP4 Secretary, Daresbury Laboratory, Warrington WA4 4AD, UK.
#
#CCP4i_cvs_Id $Id$
#CCP4I SCRIPT TEMPLATE maprot
1 MODE $MAPROT_MODE
{ [IfSet $SPACE_GROUP ] } SYMMETRY WORK $SPACE_GROUP

$IFXYZLIM XYZLIM $XYZLIM_1 $XYZLIM_2 $XYZLIM_3 $XYZLIM_4 $XYZLIM_5 $XYZLIM_6

$IFGRID GRID $MAPROT_MAP_TYPE $GRID_1 $GRID_2 $GRID_3
$IFCELL CELL $MAPROT_MAP_TYPE $CELL_1 $CELL_2 $CELL_3 $CELL_4 $CELL_5 $CELL_6

{ [IfSet $SCALE] } scale $SCALE
{ [StringSame $MAPROT_MODE CORR] && [IfSet $RADIUS] } radius $RADIUS

LOOP J 1 $NCS_NOPS
  1 AVERAGE
  1 ROTATE $NCS_OP_CONVENTION($J) $NCS_OP_ALPHA($J) $NCS_OP_BETA($J) $NCS_OP_GAMMA($J)
  1 TRANS $NCS_OP_XTRAN($J) $NCS_OP_YTRAN($J) $NCS_OP_ZTRAN($J)
ENDLOOP


