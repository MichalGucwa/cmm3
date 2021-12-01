#
#     This code is distributed under the terms and conditions of the
#     CCP4 Program Suite Licence Agreement as a CCP4 Library.
#     A copy of the CCP4 licence can be obtained by writing to the
#     CCP4 Secretary, Daresbury Laboratory, Warrington WA4 4AD, UK.
#
#     Original shelxd interface written by Thomas Pape & Thomas R. Schneider
#     Extended for CCP4 by Peter Briggs
#
#CCP4i_cvs_Id $Id$
{[IfSet $TITLE]} TITLE $TITLE
{[IfSet $CELL_LAMBDA]} CELL $CELL_LAMBDA $CELL_1  $CELL_2 $CELL_3 $CELL_4 $CELL_5 $CELL_6
{[IfSet $CELL_Z]} ZERR $CELL_Z $CELL_ERR_1 $CELL_ERR_2 $CELL_ERR_3 $CELL_ERR_4 $CELL_ERR_5 $CELL_ERR_6
{[IfSet $LATTICE]} LATT $LATTICE
LOOP n 1 $NSYMM
1 SYMM $SYMM($n)
ENDLOOP
1
CASE $SHELX_MODE
CASEMATCH HEAVY_ATOM
  1 SFAC $SFAC_LIST
  1 UNIT $UNIT_LIST
  1 SHEL $SHEL_DMIN $SHEL_DMAX
  $PATS_ONOFF PATS
  1 FIND $NHEAVY
  1 TEST 10 99
  1 MIND -$MDIS_HA $MDEQ
  1 NTRY $NTRY
  $SEED_ONOFF SEED $SEED_NRAND
CASEMATCH DIRECT
  1 SFAC $ATOM_TYPE_LIST
  1 UNIT $NATOMS_LIST
  1 MIND -$MDIS_DM $MDEQ
  CASE $DM_SEED_ONOFF
  CASEMATCH 0
    1 FIND $FIND_NATOMS
    1 PLOP $PLOP_LIST
    1 NTRY $NTRY
    $SEED_ONOFF SEED $SEED_NRAND
  CASEMATCH 1
    1 KEEP $DM_SEED_NATOMS
    1 PLOP $PLOP_LIST
    LOOP n 1 $DM_SEED_NATOMS
      {$DM_SEED_USE($n)} $DM_SEED_AT($n)$n $DM_SEED_SFAC($n) $DM_SEED_X($n) $DM_SEED_Y($n) $DM_SEED_Z($n) 11.0 $DM_SEED_B($n)
    ENDLOOP
  ENDCASE
ENDCASE
$ESEL_ONOFF ESEL $ESEL_EMIN
1
1 HKLF $SHELX_HKLF
1 END
