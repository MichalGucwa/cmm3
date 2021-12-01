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
# WATERTIDY: COMMAND SCRIPT
##################################################

##################################################
# Include title in PDB file
##################################################
{[IfSet $TITLE ] } title $TITLE

##################################################
# Specify the shell
##################################################

1 shell $WATERTIDY_SHELL

##################################################
# Supply symmetry operations or spacegroup
##################################################

IF { [StringSame $SYMM_MODE SPGRP] }
  1 symmetry $SPACE_GROUP
ELSE
  LOOP n 1 $NSYMM
    1 symmetry $SYMOP($n)
  ENDLOOP
ENDIF

##################################################
# supply chain ids
##################################################

LOOP n 1 $NHOST_CHAIN
{ [IfSet $CHAIN_ID($n) ] && [IfSet $WATOUT_ID($n) ] } chnid $CHAIN_ID($n) watoutid $WATOUT_ID($n)
    - {[IfSet $CHAIN_RES_1($n)] && [IfSet $CHAIN_RES_2($n)] } range $CHAIN_RES_1($n) $CHAIN_RES_2($n)
ENDIF
ENDLOOP

1 watid $WATIN_ID

##################################################
# other parameters
##################################################
# additional acceptors
{ [IfSet $ACCEPTORS ] } accept $ACCEPTORS

# H-bonds per acceptor
{ [IfSet $HBOND ] } hbond $HBOND

# occupancy for secondary sits

{ [IfSet $OCCW ] } occw $OCCW


1 END
