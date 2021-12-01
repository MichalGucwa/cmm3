#
#     Copyright (C) 1999-2004  Liz Potterton, Peter Briggs
#
#     This code is distributed under the terms and conditions of the
#     CCP4 Program Suite Licence Agreement as a CCP4 Library.
#     A copy of the CCP4 licence can be obtained by writing to the
#     CCP4 Secretary, Daresbury Laboratory, Warrington WA4 4AD, UK.
#
#CCP4i_cvs_Id $Id$
#CCP4I SCRIPT TEMPLATE dm
1 mode
 - $DM_SOLVENT SOLV
 - { !$DM_HISTOGRAM } NOHIST
 - { $DM_HISTOGRAM } HIST
 - $DM_SKELETON SKEL
 - $DM_SAYRE SAYR
 - $DM_AVERAGING AVER
 - $DM_MULTI MULT

1 combine $PHASE_COMB 
  - $NOCOMBINE nocombine
  - restore $DM_RESTORE_WT

1 scheme $DM_SCHEME 
IF { [StringSame $DM_SCHEME RES ] }
  - 1 from $DM_SCHEME_RES
ELSE
  - {![StringSame $DM_SCHEME ALL ] && [IfSet $DM_SCHEME_FRAC]} frac $DM_SCHEME_FRAC
ENDIF

1 ncycles
 - $DM_NCYCLES_NOT_AUTO  $DM_NCYCLES | AUTO

1 solc $SOLVENT_FRAC
- {[IfSet $SOLC_MEAN_SOLVVAL] && [IfSet $SOLC_MEAN_PROTVAL]} mean $SOLC_MEAN_SOLVVAL $SOLC_MEAN_PROTVAL

$EXCLUDE_RESOLUTION  resolution $EXCLUDE_RESOLUTION_MAX $EXCLUDE_RESOLUTION_MIN

{[IfSet $SOLMASK_FRAC_SOLV] || $IF_SOLMASK_UPDATE || $IF_SOLMASK_WANG } solmask 
  - {[IfSet $SOLMASK_FRAC_SOLV]} frac $SOLMASK_FRAC_SOLV
  -- {[IfSet $SOLMASK_FRAC_PROT]} $SOLMASK_FRAC_PROT
  - $IF_SOLMASK_UPDATE update $SOLMASK_UPDATE_NCYC
  - $IF_SOLMASK_WANG radius $WANG_RADIUS $WANG_MODE

IF $DM_AVERAGING
LOOP I 1 $NCS_NDOMAINS
  IF { $NCS_NOPS($I) > 0 } 
    LOOP J 1 $NCS_NOPS($I)
    1 average 
    - { $NCS_NDOMAINS > 1 } domain $I
    - $NCS_REFINE_OP($I) REFI
      IF { [StringSame $NCS_OP_TYPE EULER POLAR MATRIX] }
        1 rota $NCS_OP_TYPE
        IF { [StringSame $NCS_OP_TYPE EULER POLAR ] }
        - 1 $NCS_OP_ALPHA($I,$J) $NCS_OP_BETA($I,$J) $NCS_OP_GAMMA($I,$J)
        ELSE
        - 1 $NCS_OP_R11($I,$J) $NCS_OP_R12($I,$J) $NCS_OP_R13($I,$J)
        - 1 $NCS_OP_R21($I,$J) $NCS_OP_R22($I,$J) $NCS_OP_R23($I,$J)
        - 1 $NCS_OP_R31($I,$J) $NCS_OP_R32($I,$J) $NCS_OP_R33($I,$J)
        ENDIF
        1 tran $NCS_OP_XTRAN($I,$J) $NCS_OP_YTRAN($I,$J) $NCS_OP_ZTRAN($I,$J)
      ELSE
        1 omat
        1 $NCS_OP_R11($I,$J) $NCS_OP_R12($I,$J) $NCS_OP_R13($I,$J)
        1 $NCS_OP_R21($I,$J) $NCS_OP_R22($I,$J) $NCS_OP_R23($I,$J)
        1 $NCS_OP_R31($I,$J) $NCS_OP_R32($I,$J) $NCS_OP_R33($I,$J)
        1 $NCS_OP_XTRAN($I,$J) $NCS_OP_YTRAN($I,$J) $NCS_OP_ZTRAN($I,$J)
      ENDIF
    ENDLOOP
  ENDIF
ENDLOOP
ENDIF

$NCSMASK ncsmask 
  - { [IfSet $NCSMASK_NMER] } nmer $NCSMASK_NMER
  - { [IfSet $NCSMASK_ALIM_1] } ALIM $NCSMASK_ALIM_1 $NCSMASK_ALIM_2
  - { [IfSet $NCSMASK_BLIM_1] } BLIM $NCSMASK_BLIM_1 $NCSMASK_BLIM_2
  - { [IfSet $NCSMASK_CLIM_1] } CLIM $NCSMASK_CLIM_1 $NCSMASK_CLIM_2
   - $IF_NCSMASK_UPDATE update $NCSMASK_UPDATE_NCYC

$DM_SKELETON skel length $DM_SKEL_JOINLEN $DM_SKEL_ENDLEN bfac $DM_SKEL_BFAC

$IF_DM_REALFREE realfree
  - {[IfSet $DM_SX] && [IfSet $DM_SY] && [IfSet $DM_SZ] && [IfSet $DM_SR]} solv $DM_SX $DM_SY $DM_SZ $DM_SR
  - {[IfSet $DM_PX] && [IfSet $DM_PY] && [IfSet $DM_PZ] && [IfSet $DM_PR]} prot $DM_PX $DM_PY $DM_PZ $DM_PR
 
$GRID grid $GRID_1 $GRID_2 $GRID_3

# LABELLINE no longer works because of conflict of FDM in LABIN and LABOUT
1 LABIN FP = $FP SIGFP = $SIGFP PHIO = $PHIO FOMO = $FOMO
 - $USE_HL HLA = $HLA HLB = $HLB HLC = $HLC HLD = $HLD
 - $USE_COEFFS FDM = $FDMIN PHIDM = $PHIDMIN

LABELLINE LABOUT $LABOUT

AT { [FileJoin [GetEnvPath CCP4I_TOP] templates harvest.com ] }

1 END

