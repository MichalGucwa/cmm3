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
{ [IfSet $SPACE_GROUP] } symmetry $SPACE_GROUP
{ [IfSet $CELL_1 ] } cell $CELL_1 $CELL_2 $CELL_3 $CELL_4 $CELL_5 $CELL_6
$RESOLUTION_RANGE resolution $RESOLUTION_MIN $RESOLUTION_MAX
{ [IfSet $SCALE ] } scale $SCALE
{ [IfSet $DETECTOR_XMIN ] } detector $DETECTOR_XMIN $DETECTOR_XMAX  $DETECTOR_YMIN $DETECTOR_YMAX
{ [IfSet $WAVELENGTH ] } wavelength $WAVELENGTH

$USE_MONITOR monitor $MONITOR

$REINDEX reindex $REINDEX_H , $REINDEX_K , $REINDEX_L
{ $USEBATCH && [IfSet $BATCH ] } batch $BATCH
{ [IfSet $ADDBATCH ] } addbatch $ADDBATCH
{ [IfSet $MISBATCH ] } misbatch $MISBATCH

1 input  $FORMAT

CASE $FORMAT 
CASEMATCH USER
  1 format '$FORTRAN_FORMAT'
  1 label 
  LOOP N 1 $NCOLS
  - 1 $COLUMN_NAME($N)
  ENDLOOP
CASEMATCH MTZF
  LABELLINE labin $LABIN
CASEMATCH MTZI
  LABELLINE labin $LABIN
ENDCASE

{ [StringSame $FORMAT "DENZO"] && $PHIRANGE != 1 } phirange $PHIRANGE

LOOP N 1 $N_REJECTS
 1 reject $REJECT1_H($N) $REJECT1_K($N) $REJECT1_L($N)
 { [ IfSet $REJECT2_H($N) ] } reject $REJECT2_H($N) $REJECT2_K($N) $REJECT2_L($N)
ENDLOOP

AT { [FileJoin [GetEnvPath CCP4I_TOP] templates pname.com ] }

1 end

