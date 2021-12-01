
#=MAIN PROGRAM OPTIONS==========================================================
IF { $ALIGN }
  IF { [StringSame $ALIGN_MODE CA] }
    1 -a1
  ELSE
    IF { [StringSame $ALIGN_MODE MIX] }
      1 -a2
    ELSE
      1 -a
    ENDIF
  ENDIF
ENDIF
$RESTRAIN -r

1 -o {\"$DIR_OUT\"}

#=TARGET STRUCTURES=============================================================
IF { [StringSame $C1_TYPE ALL] }
  { [IfSet $P1(1)] } -p1
  LOOP I 1 $NP1
    { [IfSet $P1($I)] } {\"$P1($I)\"}
  ENDLOOP
ELSE
  1 -p1
  LOOP I 1 $NP1
    LOOP J 1 $NC1($I)
      { [IfSet $C1($I,$J)] } {\"$P1($I)\"}
    ENDLOOP
  ENDLOOP
  1 -c1
  LOOP I 1 $NP1
    LOOP J 1 $NC1($I)
      { [IfSet $C1($I,$J)] } $C1($I,$J)
    ENDLOOP
  ENDLOOP
ENDIF

#=ALL ON ALL====================================================================
{ !$USE_LIB && $ALL_ON_ALL && !$TRIANGULAR } -allonall

#=REFERENCE STRUCTURES==========================================================
IF { !$ALL_ON_ALL && !$USE_LIB }
IF { [StringSame $C2_TYPE ALL] }
  { [IfSet $P2(1)] } -p2
  LOOP I 1 $NP2
    { [IfSet $P2($I)] } {\"$P2($I)\"}
  ENDLOOP
ELSE
  1 -p2
  LOOP I 1 $NP2
    LOOP J 1 $NC2($I)
      { [IfSet $C2($I,$J)] } {\"$P2($I)\"}
    ENDLOOP
  ENDLOOP
  1 -c2
  LOOP I 1 $NP2
    LOOP J 1 $NC2($I)
      { [IfSet $C2($I,$J)] } $C2($I,$J)
    ENDLOOP
  ENDLOOP
ENDIF
ENDIF

#=RANGE FILTERING===============================================================

IF { $RANGE_SHOW && $ALIGN} 
  LOOP I 1 $NRANGE1
    { [IfSet $RANGE1PDB($I)] && [IfSet $RANGE1CHAIN($I)] && [IfSet $RANGE1A($I)] && [IfSet $RANGE1B($I)] } -align {\"$RANGE1PDB($I)\"} $RANGE1CHAIN($I) $RANGE1A($I) $RANGE1B($I)
  ENDLOOP
  LOOP I 1 $NRANGE2
    { [IfSet $RANGE2PDB($I)] && [IfSet $RANGE2CHAIN($I)] && [IfSet $RANGE2($I)] } -align_rm {\"$RANGE2PDB($I)\"} $RANGE2CHAIN($I) $RANGE2($I)
  ENDLOOP
ENDIF
IF { $RANGE3_SHOW && $RESTRAIN} 
  LOOP I 1 $NRANGE3
    { [IfSet $RANGE3PDB($I)] && [IfSet $RANGE3CHAIN($I)] && [IfSet $RANGE3A($I)] && [IfSet $RANGE3B($I)] } -restrain {\"$RANGE3PDB($I)\"} $RANGE3CHAIN($I) $RANGE3A($I) $RANGE3B($I)
  ENDLOOP
  LOOP I 1 $NRANGE4
    { [IfSet $RANGE4PDB($I)] && [IfSet $RANGE4CHAIN($I)] && [IfSet $RANGE4($I)] } -restrain_rm {\"$RANGE4PDB($I)\"} $RANGE4CHAIN($I) $RANGE4($I)
  ENDLOOP
ENDIF

#=FRAGMENT LIBRARY OPTIONS======================================================
IF { $USE_LIB }
  { $LIB } -lib
  IF { !$LIB }
    { $HELIX } -helix
    { $STRAND } -strand
  ENDIF
  IF { $LIB_ADVANCED }
    { [IfSet $LIB_CONFIG] } -library_config $LIB_CONFIG
    { [IfSet $LIB_DIR] } -library $LIB_DIR
    { [IfSet $LIB_SCORE] } -lib_score $LIB_SCORE
    { [IfSet $LIB_FRAGLEN] } -lib_fraglen $LIB_FRAGLEN
  ENDIF
ENDIF

#=STRUCTURAL ALIGNMENT PARAMETERS===============================================
IF { $ALIGN }

IF { $FRAGLEN_SHOW }
{ [IfSet $FRAGLEN] } -len $FRAGLEN
ENDIF

IF { $ALIGN_SCORE_SHOW }
{ [IfSet $ALIGN_SCORE] } -score $ALIGN_SCORE
ENDIF

{ $SEQUENCE_IDENTICAL } -id

{ !$REFINE_ALIGNMENT } -skip_refine

IF { $ADJUST_HELIX }
{ [IfSet $HELIX_SCORE] } -helixcutoff $HELIX_SCORE
{ [IfSet $HELIX_PENALTY] } -helixpenalty $HELIX_PENALTY
ENDIF

IF { !$REWARD_SEQ_ENABLE }
  1 -no_reward_seq
ELSE
  IF { $REWARD_SEQ_SHOW }
    { [IfSet $REWARD_SEQ] } -reward_seq $REWARD_SEQ
  ENDIF
ENDIF

ENDIF

#=SCORING OPTIONS===============================================================
IF { $ALIGN }

{ $SCORE_NCO } -main_dist

{ !$SCORE_FLIP } -no_fix_errors

{ $SCORE_COSINE } -cosine

ENDIF

#=RIGID SUBSTRUCTURE IDENTIFICATION=============================================				
IF { $ALIGN }
IF { $SUBSTRUCTURE_ID }

IF { $RIGID_SCORE_SHOW }
{ [IfSet $RIGID_SCORE] } -cluster_score $RIGID_SCORE
{ [IfSet $RIGID_ANGLE] } -cluster_angle $RIGID_ANGLE
ENDIF
IF { $RIGID_LINK_SHOW }
{ [IfSet $RIGID_LINK] } -cluster_link $RIGID_LINK
{ [IfSet $RIGID_RIGID] } -cluster_rigid $RIGID_RIGID
ENDIF
IF { $RIGID_MIN_SHOW }
{ [IfSet $RIGID_MIN] } -cluster_min $RIGID_MIN
ENDIF

ELSE
1 -cluster_skip
ENDIF
ENDIF

#=RESTRAIN======================================================================
IF { $RESTRAIN }

IF { $RESTRAIN_BEST }
1 -restrain_best
ELSE
1 -restrain_all
ENDIF

IF { [StringSame $RESTRAIN_TYPE SIDE] }
1 -side
ELSE
1 -main
ENDIF

IF { [StringSame $RESTRAIN_REFMACTYPE REPLACE] }
  1 -type 0
ENDIF
IF { [StringSame $RESTRAIN_REFMACTYPE ADD] }
  1 -type 1
ENDIF

IF { $RESTRAIN_RMAX_SHOW }
{ [IfSet $RESTRAIN_RMAX] } -rmax $RESTRAIN_RMAX
{ [IfSet $RESTRAIN_RMIN] } -rmin $RESTRAIN_RMIN
ENDIF

{ $RESTRAIN_RMBONDS } -rm_bonds

IF { $RESTRAIN_SCORE_SHOW }
{ [IfSet $RESTRAIN_SCORE] } -cutoff $RESTRAIN_SCORE
{ [IfSet $RESTRAIN_SIDE] } -side_cutoff $RESTRAIN_SIDE
ENDIF

IF { $RESTRAIN_TYPE_SHOW }
IF { [StringSame $RESTRAIN_SIGMATYPE SIGMA_DD] }
1 -sigmatype 2
ELSE
    IF { [StringSame $RESTRAIN_SIGMATYPE SIGMA_EST] }
    1 -sigmatype 1
    ELSE
    1 -sigmatype 0
    ENDIF
ENDIF
{ [IfSet $RESTRAIN_SIGMA] } -sigma $RESTRAIN_SIGMA
{ [IfSet $RESTRAIN_SIGMAMIN] } -min_sigma $RESTRAIN_SIGMAMIN
{ [IfSet $RESTRAIN_SCALE] } -weight $RESTRAIN_SCALE
ENDIF

IF { $RESTRAIN_OUTLIER_SHOW }
{ [IfSet $RESTRAIN_OUTLIER] } -multiplier $RESTRAIN_OUTLIER
ENDIF

{ $RESTRAIN_GENERIC_SELF } -self_restrain

ENDIF

#=RESTRAIN_HBOND================================================================
IF { $RESTRAIN && [StringSame $SECONDARY_MODE_RESTR HBOND] }

IF { [StringSame $HBOND_MODE SSE] }
    { ![StringSame $HBOND_SSEMODE HELIX] } -h_sheet
    IF { ![StringSame $HBOND_SSEMODE SHEET] }
        { $HBOND_3 } -3_10
        { $HBOND_4 } -alpha
        { $HBOND_5 } -pi
    ENDIF
    { $HBOND_STRICT } -strict
ELSE
    1 -h
    IF { [StringSame $HBOND_MODE CUSTOM] }
        { [IfSet $HBOND_MINSEP] } -min_sep $HBOND_MINSEP
        { [IfSet $HBOND_MAXSEP] } -max_sep $HBOND_MAXSEP        
        { [IfSet $HBOND_REMOVESEP] } -rm_sep $HBOND_REMOVESEP
        { [StringSame $HBOND_OPT ON] } -bond_opt 1
        { [StringSame $HBOND_OPT ONNO] } -bond_opt 2
        { [StringSame $HBOND_OPT ALL] } -bond_opt 3
    ENDIF
ENDIF

IF { $HBOND_ALTER }
    { [IfSet $HBOND_TARGET] } -bond_dist $HBOND_TARGET
    { [IfSet $HBOND_MIN] } -bond_min $HBOND_MIN
    { [IfSet $HBOND_MAX] } -bond_max $HBOND_MAX
ENDIF

IF { $HBOND_OVERRIDE }
    { [IfSet $HBOND_OVERRIDE_VAL] } -bond_override $HBOND_OVERRIDE_VAL
ENDIF

ENDIF

#=OUTPUT_OPTIONS================================================================
IF { $ALIGN }

IF { !$OUTPUT_PDB && !$OUTPUT_COLOUR }
  1 -quick
ELSE
  IF { $OUTPUT_PDB }
    1 -out_pdb
    { $OUTPUT_PDB_FULL } -out_pdb_full
    IF { $SUPERPOSITION_SHOW }
      { [IfSet $SUPERPOSITION_SCORE] } -superpose $SUPERPOSITION_SCORE
    ENDIF
  ENDIF
  IF { $OUTPUT_COLOUR }
    1 -out_color
    IF { $COLOUR_SCORE_SHOW }
      { [IfSet $COLOUR_SCORE] } -colour_score $COLOUR_SCORE
      { [IfSet $COLOUR_SCORE_SIDE] } -side_score $COLOUR_SCORE_SIDE
      IF { $SUBSTRUCTURE_ID }
        { [IfSet $RIGID_COLOUR] } -cluster_color $RIGID_COLOUR
      ENDIF
    ENDIF
    IF { $COLOUR_SHOW }
      { [IfSet $COLOUR_S1] && [IfSet $COLOUR_S2] && [IfSet $COLOUR_S3] } -col1 $COLOUR_S1 $COLOUR_S2 $COLOUR_S3
      { [IfSet $COLOUR_D1] && [IfSet $COLOUR_D2] && [IfSet $COLOUR_D3] } -col2 $COLOUR_D1 $COLOUR_D2 $COLOUR_D3
    ENDIF
  ENDIF
ENDIF

ENDIF

IF { $RESTRAIN }
  { $OUTPUT_EXTRA_RESTRAINTS } -output_pdb_chain_restraints
ENDIF

#=ADVANCED======================================================================

IF { $THREADS_SHOW }
  { [IfSet $THREADS] } -threads $THREADS
ENDIF

IF { $XML }
IF { [IfSet $XML_FILE] }
  1 -xml $XML_FILE
ELSE
  1 -xml
ENDIF
ENDIF

IF { $RESTRAIN && $REFMAC_SHOW}
  { [IfSet $REFMAC] } -refmac $REFMAC
ENDIF

#=EXTERNAL KEYWORDS=============================================================

{ [IfSet $KEYWORDS] } -f {\"$KEYWORDS\"}

{ [IfSet $EXTRA_KEYWORDS] } $EXTRA_KEYWORDS




