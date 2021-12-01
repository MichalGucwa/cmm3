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
# FFJOIN: COMMAND SCRIPT
##################################################

##################################################
# JOIN keyword
##################################################

1 JOIN RADIUS $JOIN_RADIUS
- 1 OVERLAP $JOIN_OVERLAP
- $JOIN_NOREVERSE NOREVERSE

##################################################
# BUMP keyword
##################################################

IF {$DELETE_CLASH}
 1 BUMP RADIUS $BUMP_RADIUS
ELSE
 1 BUMP NOBUMP
ENDIF

##################################################
# END of script
##################################################

1 END



