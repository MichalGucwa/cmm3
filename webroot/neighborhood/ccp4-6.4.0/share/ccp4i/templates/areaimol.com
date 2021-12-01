#
#     Copyright (C) 1999-2004  Liz Potterton, Peter Briggs
#
#     This code is distributed under the terms and conditions of the
#     CCP4 Program Suite Licence Agreement as a CCP4 Library.
#     A copy of the CCP4 licence can be obtained by writing to the
#     CCP4 Secretary, Daresbury Laboratory, Warrington WA4 4AD, UK.
#
##################################################
# AREAIMOL: COMMAND SCRIPT
##################################################
#CCP4i_cvs_Id $Id$

1 DIFFMODE $DIFFMODE

#---------------------------------------------------
# MODE
#---------------------------------------------------
1 MODE
IF { [StringSame $DIFFMODE OFF] }
  - 1 $WATERS_MODE
ELSE
  - 1 NOHOH
ENDIF

#---------------------------------------------------
# SMODE
#---------------------------------------------------
IF { ![StringSame $DIFFMODE IMOL] }
  IF { $SYMMETRY_MODE }
    1 SMODE IMOL
  ELSE
    1 SMODE OFF
  ENDIF
ENDIF

#---------------------------------------------------
# Intermolecular contacts
#---------------------------------------------------
IF { [StringSame $DIFFMODE IMOL] || $SYMMETRY_MODE }
  IF { [StringSame $SYMM_SOURCE SPGRP] }
    1 SYMMETRY $SPACE_GROUP
  ELSE
    1 SYMMETRY
    LOOP N 1 $NSYMM
    - 1 $SYMOP($N)
    ENDLOOP
  ENDIF
  $USE_TRANSLATIONS TRANS
  IF { [StringSame $DIFFMODE IMOL] }
    - 1 1
  ENDIF
ENDIF

#---------------------------------------------------
# Van der Waals radii
#---------------------------------------------------
LOOP N 1 $N_ATOMS
  1 ATOM $ATOM_NAME($N) $ATOM_NUMBER($N) $ATOM_RADIUS($N) 
ENDLOOP

#---------------------------------------------------
# Reporting options
#---------------------------------------------------
1 REPORT
- 1 CONTACT
IF { $REPORT_CONTACT }
  - 1 YES
ELSE
  - 1 NO
ENDIF
- 1 RESAREA
IF { $REPORT_RESAREA }
  - 1 YES
ELSE
  - 1 NO
ENDIF

#---------------------------------------------------
# Miscellaneous other options
#---------------------------------------------------
1 PNTDEN $PNTDEN
1 PROBE $PROBE_RADIUS
$WRITE_OUTPUT_FILE OUTPUT
1 END
