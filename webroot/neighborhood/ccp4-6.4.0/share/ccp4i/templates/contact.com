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
# CONTACT: COMMAND SCRIPT
##################################################

##################################################
# Include title
##################################################
{[IfSet $TITLE ] } title $TITLE

##################################################
# Which mode? For METALs omit MODE keyword
##################################################
IF { [StringSame $CONTACT_MODE METAL] }
  1 metal $METAL_NAME $METAL_LIGAND_DIST
ELSE
  1 mode $CONTACT_MODE
ENDIF

##################################################
# Supply symmetry operations or spacegroup
##################################################

IF { [StringSame $CONTACT_MODE METAL AUTO] }

  IF { [StringSame $SYMM_MODE SPGRP] }
    1 spacegroup $SPACE_GROUP
  ELSE
    LOOP n 1 $NSYMM
      1 symmetry $SYMOP($n)
    ENDLOOP
  ENDIF

ENDIF

{ [StringSame $SEARCH_VOL BIG] } bigsearch

##################################################
# Contact distances
##################################################

1 limit $MIN_DIST $MAX_DIST

##################################################
# Atom/residue selections
##################################################

IF { [StringSame $SOURCE_TYPE ATOMS RESIDUES]}
1 from -
CASE $SOURCE_TYPE 
CASEMATCH ATOMS
  1   atom $SOURCE_NUMA1 to $SOURCE_NUMA2
CASEMATCH RESIDUES
  1   residue $SOURCE_ATYPE
  - {[IfSet $SOURCE_CHN ]} chain $SOURCE_CHN
  - 1 $SOURCE_NUMR1 to $SOURCE_NUMR2
ENDCASE
ENDIF

IF { [StringSame $TARGET_TYPE ATOMS RESIDUES]}
1 to -
CASE $TARGET_TYPE 
CASEMATCH ATOMS
  1   atom $TARGET_NUMA1 to $TARGET_NUMA2
CASEMATCH RESIDUES
  1   residue $TARGET_ATYPE
  - {[IfSet $TARGET_CHN ]}  chain $TARGET_CHN
  - 1 $TARGET_NUMR1 to $TARGET_NUMR2
ENDCASE
ENDIF
##################################################
# Other options
##################################################

$HEXCLUDE hexclude
$ANGLE angle
