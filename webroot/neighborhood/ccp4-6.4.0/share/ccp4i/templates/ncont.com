#
#     Copyright (C) 2005  Martyn Winn
#
#     This code is distributed under the terms and conditions of the
#     CCP4 Program Suite Licence Agreement as a CCP4 Library.
#     A copy of the CCP4 licence can be obtained by writing to the
#     CCP4 Secretary, Daresbury Laboratory, Warrington WA4 4AD, UK.
#
#CCP4i_cvs_Id $Id$
##################################################
# NCONT: COMMAND SCRIPT
##################################################

1 source \\\"$NCONT_SOURCE\\\"
1 target \\\"$NCONT_TARGET\\\"
1 mindist $MIN_DIST
1 maxdist $MAX_DIST
1 cells $NCONT_MODE
IF { ![ StringSame $NCONT_MODE OFF ] }
1 symm $SPACE_GROUP
ENDIF
{$SET_GEOM} geometry $CELL_A $CELL_B $CELL_C $CELL_ALPHA $CELL_BETA $CELL_GAMMA
{$SET_SEQDIST} seqdist $SEQDIST
1 END
