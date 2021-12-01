#
#     Copyright (C) 1999-2004  Liz Potterton, Peter Briggs
#
#     This code is distributed under the terms and conditions of the
#     CCP4 Program Suite Licence Agreement as a CCP4 Library.
#     A copy of the CCP4 licence can be obtained by writing to the
#     CCP4 Secretary, Daresbury Laboratory, Warrington WA4 4AD, UK.
#
#CCP4i_cvs_Id $Id$
1 scheme $DM_SCHEME 
IF { [StringSame $DM_SCHEME RES ] }
  - {[IfSet $DM_SCHEME_RES]} from $DM_SCHEME_RES
ELSE
  - {![StringSame $DM_SCHEME AUTO ] && [IfSet $DM_SCHEME_FRAC]} frac $DM_SCHEME_FRAC
ENDIF

1 ncycles $DM_NCYCLES free $DM_NCROSS

$DM_SKELETON skel 
  - {[IfSet$DM_SKEL_JOINLEN]} length $DM_SKEL_JOINLEN $DM_SKEL_ENDLEN 
  - {[IfSet $DM_SKEL_BFAC]} bfac $DM_SKEL_BFAC 
  - {IfSet $DM_SKEL_CYCLES]} every $DM_SKEL_CYCLES
{[IfSet $SCALE_SCALE]} SCALE $SCALE_SCALE
  - {[IfSet $SCALE_BFAC]} $SCALE_BFAC
$GRID grid $GRID_1 $GRID_2 $GRID_3
{[IfSet $WANG_RADIUS]} wang $WANG_RADIUS $WANG_MODE \
  - {[IfSet $WANG_RHO_MIN]} limits $WANG_RHO_MIN $WANG_RHO_MAX

LOOP NX 1 $NCRYSTALS
1 xtal $NX
1 mode
 - $DM_SOLVENT SOLV
 - $DM_HISTOGRAM HIST
 - $DM_SKELETON SKEL
 - $DM_AVERAGING AVER
{[IfSet $RESOLUTION_MIN($NX)]} resolution $RESOLUTION_MIN($NX)
- {[IfSet $RESOLUTION_MAX($NX)]} $RESOLUTION_MAX($NX)
1 solc $SOLVENT_FRAC($NX)
- {[IfSet $SOLC_MASK_SOLV($NX)] && [IfSet $SOLC_MASK_PROT($NX)]} mask $SOLC_MASK_SOLV($NX) $SOLC_MASK_PROT($NX)
- {[IfSet $SOLC_MEAN_SOLVVAL($NX)] && [IfSet $SOLC_MEAN_PROTVAL($NX)]} mean $SOLC_MEAN_SOLVVAL($NX) $SOLC_MEAN_PROTVAL($NX)
LABELLINE LABIN $LABIN($NX) $NX  noprog
LABELLINE LABOUT $LABOUT($NX)
LOOP I 1 $NCS_NOPS($NX)
    1 average
    - { $NDOMAINS > 1 } domain $NCS_OP_DOM($NX,$I)
    - { $XTAL_REFINE_OP($NX) } REFI
      1 rota euler $NCS_OP_ALPHA($NX,$I) $NCS_OP_BETA($NX,$I) $NCS_OP_GAMMA($NX,$I)
      1 tran $NCS_OP_XTRAN($NX,$I) $NCS_OP_YTRAN($NX,$I) $NCS_OP_ZTRAN($NX,$I)
ENDLOOP
ENDLOOP


1 END

