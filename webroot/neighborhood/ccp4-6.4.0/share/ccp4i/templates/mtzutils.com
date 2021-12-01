#
#     Copyright (C) 1999-2004  Liz Potterton, Peter Briggs
#
#     This code is distributed under the terms and conditions of the
#     CCP4 Program Suite Licence Agreement as a CCP4 Library.
#     A copy of the CCP4 licence can be obtained by writing to the
#     CCP4 Secretary, Daresbury Laboratory, Warrington WA4 4AD, UK.
#
#CCP4i_cvs_Id $Id$
{ [IfSet $TITLE ] } TITLE $TITLE
{ [IfSet $SPACE_GROUP ] } SYMMETRY $SPACE_GROUP
{ [IfSet $CELL_1 ] } CELL $CELL_1 $CELL_2 $CELL_3 $CELL_4 $CELL_5 $CELL_6
$EXCLUDE_RESOLUTION RESOLUTION $RESOLUTION_MIN $RESOLUTION_MAX

$IFZONE AXIS $ZONE
$IFRZONE RZONE $RZONE_1 $RZONE_2 $RZONE_3 $RZONE_4 $RZONE_5


LABELLINE LABIN $LABIN
1 HEADER $HEADER
1 END
