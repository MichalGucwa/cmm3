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
# Save title as a REMARK
##################################################
{ [IfSet $TITLE ] } remark $TITLE


##################################################
# Are we inputing a new spacegroup
##################################################
IF $IF_CELL
{[IfSet $SPACE_GROUP ] } spacegroup $SPACE_GROUP
{[IfSet $CELL_1 ] } cell $CELL_1 $CELL_2 $CELL_3 $CELL_4 $CELL_5 $CELL_6
{IF ![regexp CODE0 $PDBSET_NCODE ] } orthogonalisation $PDBSET_NCODE
ENDIF

##################################################
# Input or Output files in XPLOR format
##################################################
$IFXPLOR XPLOR $IFXPLOR_HYDROGEN hydrogen

$IFOUT_XPLOR OUTPUT $IFOUT_XPLOR XPLOR

##################################################
# Selecting items for output to PDB file
##################################################
IF { [StringSame $PDBSET_ACTION SELECT]}

# on B-Factor
IF { $OUTPUT_BFACTOR && [IfSet $OUTPUT_SEL_BFACT ] }
  1 select bfactor $OUTPUT_SEL_BFACT
ENDIF

# on occupancy
IF { $OUTPUT_OCCUPANCY && [IfSet $OUTPUT_SEL_OCC ] }
  1 select occupancy $OUTPUT_SEL_OCC
ENDIF

# on chain name
IF { $OUTPUT_CHAIN }
1 select chain
IF { $NOUT_CHAINS > 0 }
LOOP n 1 $NOUT_CHAINS
    - {[IfSet $OUT_CHAIN1($n)] } $OUT_CHAIN1($n)
    - {[IfSet $OUT_CHAIN2($n)] } $OUT_CHAIN2($n)
    - {[IfSet $OUT_CHAIN3($n)] } $OUT_CHAIN3($n)
    - {[IfSet $OUT_CHAIN4($n)] } $OUT_CHAIN4($n)
    - {[IfSet $OUT_CHAIN5($n)] } $OUT_CHAIN5($n)
ENDLOOP
ENDIF
ENDIF

# on atom type
IF { $OUTPUT_PICK }
1 pick
IF { $NOUT_ATOMS > 0 }
LOOP n 1 $NOUT_ATOMS
    - {[IfSet $OUT_ATOM1($n)] } $OUT_ATOM1($n)
    - {[IfSet $OUT_ATOM2($n)] } $OUT_ATOM2($n)
    - {[IfSet $OUT_ATOM3($n)] } $OUT_ATOM3($n)
    - {[IfSet $OUT_ATOM4($n)] } $OUT_ATOM4($n)
    - {[IfSet $OUT_ATOM5($n)] } $OUT_ATOM5($n)
ENDLOOP
ENDIF
ENDIF

# exclude header
$EXCLUDE_HEADER exclude header

# exclude side chain (warning about N's)
$EXCLUDE_SIDE exclude side

# exclude water groups
$EXCLUDE_WATER exclude water

ENDIF

##################################################
# Renumber residues and rename chains
##################################################
IF { [StringSame $PDBSET_ACTION RENAME ]}

IF { $NRENUMBER > 0 }
# renumber residues 
LOOP n 1 $NRENUMBER
IF { [regexp RENUMBER $EDIT_MODE($n) ] || [IfSet $RENUMBER_RANGE_1($n)] } 
  1 renumber 
  CASE $RENUMBER_MODE($n)
  CASEMATCH INC
IF {[IfSet $RENUMBER_INC($n)]}
    - 1 increment $RENUMBER_INC($n) 
ELSE
    - 1 increment 0
ENDIF
  CASEMATCH INIT
    - {[IfSet $RENUMBER_INIT($n)]} $RENUMBER_INIT($n) 
  CASEMATCH {}
    - 1 $RENUMBER_RANGE_1($n)
  ENDCASE
  - {[IfSet $RENUMBER_RANGE_1($n)]} $RENUMBER_RANGE_1($n) to $RENUMBER_RANGE_2($n)
  - {[IfSet $RENUMBER_CHAIN($n)]} chain $RENUMBER_CHAIN($n)
  -- {[IfSet $RENUMBER_NEW_CHAIN($n)]} to $RENUMBER_NEW_CHAIN($n)
ELSE
# rename chain
  {[IfSet $RENUMBER_CHAIN($n)]} chain $RENUMBER_CHAIN($n) $RENUMBER_NEW_CHAIN($n)
ENDIF
ENDLOOP
ENDIF

ENDIF

##################################################
# Rename residues and atom types
##################################################
IF { [StringSame $PDBSET_ACTION REPLACE ]}

IF { $NREPLACE > 0 } 
LOOP n 1 $NREPLACE
  1 replace
  CASE $REPLACE_MODE($n)
  CASEMATCH REPLACE_RESIDUE
    - 1 residue $REPLACE_RES($n) by $WITH_RES($n) 
  CASEMATCH REPLACE_ATOM
    - 1 atom \\\"$REPLACE_ATOM($n)\\\" by \\\"$WITH_ATOM($n)\\\"
    - {[IfSet $IN_RES($n)]} in $IN_RES($n)
  ENDCASE
ENDIF
ENDLOOP
ENDIF

ENDIF

##################################################
# SYMGEN of new chains
##################################################
IF { [ StringSame $PDBSET_ACTION SYMMETRY ]}

# use Spacegroup
IF { [regexp SYMGEN_SPACE $SYMGEN_MODE] } 
 {[IfSet $SYMGEN_GRP ]} symgen $SYMGEN_GRP
ENDIF

# use symmetry operations
IF { [regexp SYMGEN_OP $SYMGEN_MODE] && $NSYMGEN > 0 } 
LOOP n 1 $NSYMGEN
 {[IfSet $SYMGEN($n)]} symgen $SYMGEN($n)
IF { [regexp NCS $SYMGEN($n) ] }
# NCS symmetry operation (Transfrom)
 1 transform
  - $NCS_INVERT($n) invert
  - { [regexp FRACT $NCS_ISFRACT($n) ] } fractional
  - 1 $RN_11($n) $RN_12($n) $RN_13($n) 
  - 1 $RN_21($n) $RN_22($n) $RN_23($n) 
  - 1 $RN_31($n) $RN_32($n) $RN_33($n)
  - 1 $TN_X($n) $TN_Y($n) $TN_Z($n)
ENDIF
ENDLOOP
ENDIF

# rename chains due to symmetry operation
IF { $NSYM_CHAIN_RENAME > 0 }
LOOP n 1 $NSYM_CHAIN_RENAME
 { [IfSet $NSYM_CHAIN_SYM($n) ] } chain symmetry $NSYM_CHAIN_SYM($n) 
- 1 $NSYM_OLD_CHAIN($n) $NSYM_NEW_CHAIN($n)
ENDLOOP
ENDIF

ENDIF

##################################################
# Shift/Rotate coordinates
##################################################
IF { [ StringSame $PDBSET_ACTION ROTATE ]}

# rotational element
IF { [ StringSame $TRANS_TYPE BOTH ROTATE ] }
1 rotate
  - $NCS_TRAN_INVERT invert
IF { [regexp EULER $NCS_ROT_TYPE ] }
  - 1 euler
  - 1 $R_ALPHA $R_BETA $R_GAMMA
ENDIF
IF {[regexp POLAR $NCS_ROT_TYPE ]}
  - 1 polar
  - 1 $R_OMEGA $R_PHI $R_KAPPA
ENDIF
IF { [regexp MATRIX $NCS_ROT_TYPE ] }
  - matrix
  - 1 $R_11 $R_12 $R_13 
  - 1 $R_21 $R_22 $R_23 
  - 1 $R_31 $R_32 $R_33
ENDIF
ENDIF

# translational element
IF { [ StringSame $TRANS_TYPE BOTH SHIFT ] }
IF { $T_X != 0.0 || $T_Y != 0.0 || $T_Z != 0.0 }
1 shift
  - $NCS_TRAN_INVERT invert
IF { [regexp FRACT $NCS_TRAN_ISFRACT ] }
  - 1 fractional
ENDIF
  - 1 $T_X $T_Y $T_Z
ENDIF
ENDIF

ENDIF


$IFBFACTOR bfactor $BFACTOR_MODE $BFACTOR_VALUE1 
- {[regexp RANGE $BFACTOR_MODE]} $BFACTOR_VALUE2

$IFOCCUPANCY occupancy $OCCUPANCY_MODE $OCCUPANCY_VALUE

##################################################
# Average Bfactors
##################################################
IF { [ StringSame $PDBSET_ACTION AVERAGE ]}
1 bfactor AVERAGE
ENDIF

1 end

