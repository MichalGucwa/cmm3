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
{ [IfSet $SPACE_GROUP ] } symmetry $SPACE_GROUP
{ [IfSet $CELL_1] } cell $CELL_1 $CELL_2 $CELL_3 $CELL_4 $CELL_5 $CELL_6

$ANOMALOUS anomalous

AT { [FileJoin [GetEnvPath CCP4I_TOP] templates pname.com ] }
1 end
