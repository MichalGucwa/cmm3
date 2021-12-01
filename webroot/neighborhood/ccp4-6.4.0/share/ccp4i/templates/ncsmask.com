#
#     Copyright (C) 1999-2004  Liz Potterton, Peter Briggs
#
#     This code is distributed under the terms and conditions of the
#     CCP4 Program Suite Licence Agreement as a CCP4 Library.
#     A copy of the CCP4 licence can be obtained by writing to the
#     CCP4 Secretary, Daresbury Laboratory, Warrington WA4 4AD, UK.
#
#CCP4i_cvs_Id $Id$
{ [IfSet $SPACE_GROUP ] } SYMMETRY $SPACE_GROUP

$IFGRID GRID $GRID_1 $GRID_2 $GRID_3
$IFCELL CELL $CELL_1 $CELL_2 $CELL_3 $CELL_4 $CELL_5 $CELL_6
$IFAXIS axis $AXIS

{ [StringSame $NCSMASK_MODE CREATE] && [IfSet $RADIUS] } radius $RADIUS
$IFPEAK peak $PEAK
$IFSMOOTH smooth $SMOOTH
$IFMONOMER monomer
$IFOVERLAP overlap $OVERLAP_NCYCLE
{ !$IFTRIM || $IFXYZLIM } notrim

$IFXYZLIM XYZLIM $XYZLIM_1 $XYZLIM_2 $XYZLIM_3 $XYZLIM_4 $XYZLIM_5 $XYZLIM_6
$IFEXPAND expand $EXPAND

IF { $IFNCS && [IfSet $NCS_NOPS] && $NCS_NOPS > 0 } 
1 average $NCS_NOPS
LOOP J 1 $NCS_NOPS
  1 rota euler $NCS_OP_ALPHA($J) $NCS_OP_BETA($J) $NCS_OP_GAMMA($J)
  1 tran $NCS_OP_XTRAN($J) $NCS_OP_YTRAN($J) $NCS_OP_ZTRAN($J)
ENDLOOP
ENDIF


