#
# ARP/wARP + REFMAC5 Section (Model building and refinement)
#
IF { [StringSame $PROGRAM_NAME($I) ARPWARP] } 
1   <input>
1      <substructure>$INPUT_SUBSTRUCTURE($I)</substructure>
1      <pdb>$INPUT_PDB($I)</pdb>
1      <exp_columns>
LOOP K 1 $N_CRYSTALS
1         <crystal id="$K">
IF $CRYSTAL_NATIVE($K)
1            <data id="1">
1               <f>$INPUT_EXPERIMENTAL_COLUMNS($I)_X${K}_D1_F</f>
1               <sigf>$INPUT_EXPERIMENTAL_COLUMNS($I)_X${K}_D1_SIGF</sigf>
1               <anomalous>0</anomalous>
1            </data>
ELSE
LOOP M 1 $N_DATA($K)
1            <data id="$M">
1               <f>$INPUT_EXPERIMENTAL_COLUMNS($I)_X${K}_D1_F</f>
1               <sigf>$INPUT_EXPERIMENTAL_COLUMNS($I)_X${K}_D1_SIGF</sigf>
IF $DATA_ANOMALOUS($K,$M)
1               <f_plus>$INPUT_EXPERIMENTAL_COLUMNS($I)_X${K}_D${M}_F+</f_plus>
1               <sigf_plus>$INPUT_EXPERIMENTAL_COLUMNS($I)_X${K}_D${M}_SIGF+</sigf_plus>
1               <f_minus>$INPUT_EXPERIMENTAL_COLUMNS($I)_X${K}_D${M}_F-</f_minus>
1               <sigf_minus>$INPUT_EXPERIMENTAL_COLUMNS($I)_X${K}_D${M}_SIGF-</sigf_minus>
ENDIF
1            </data>
ENDLOOP
ENDIF
1         </crystal>
ENDLOOP
1      </exp_columns>
1      <phase_columns>
1         <f>$INPUT_PHASE_COLUMNS($I)_F</f>
1         <sigf>$INPUT_PHASE_COLUMNS($I)_SIGF</sigf>
1         <phib>$INPUT_PHASE_COLUMNS($I)_PHIB</phib>
1         <fom>$INPUT_PHASE_COLUMNS($I)_FOM</fom>
1      </phase_columns>
1      <hl_columns>
1         <hla>$INPUT_HL_COLUMNS($I)_HLA</hla>
1         <hlb>$INPUT_HL_COLUMNS($I)_HLB</hlb>
1         <hlc>$INPUT_HL_COLUMNS($I)_HLC</hlc>
1         <hld>$INPUT_HL_COLUMNS($I)_HLD</hld>
1      </hl_columns>
1      <freer_columns>
1         <freer>$INPUT_FREER_COLUMNS($I)_FREER</freer>
1      </freer_columns>
1   </input>
1   <output>
1      <substructure>$PROGRAM_TAG($I)</substructure>
1      <pdb>$PROGRAM_TAG($I)</pdb>
1      <phase_columns>
1         <f>$OUTPUT_PHASE_COLUMNS($I)_F</f>
1         <sigf>$OUTPUT_PHASE_COLUMNS($I)_SIGF</sigf>
1         <phib>$OUTPUT_PHASE_COLUMNS($I)_PHIB</phib>
1         <fom>$OUTPUT_PHASE_COLUMNS($I)_FOM</fom>
1      </phase_columns>
1      <freer_columns>
1         <freer>$OUTPUT_FREER_COLUMNS($I)_FREER</freer>
1      </freer_columns>
1   </output>
1   <arpwarp>
1      <use_six>$ARPWARP_USE_SIX($I)</use_six>
1      <side_after>$ARPWARP_SIDE_AFTER($I)</side_after>
1      <small_cycles>$ARPWARP_SMALL_CYCLES($I)</small_cycles>
1      <big_cycles>$ARPWARP_BIG_CYCLES($I)</big_cycles>
1      <exclude_freer>$ARPWARP_EXCLUDE_FREER($I)</exclude_freer>
1      <ncycles>$ARPWARP_NCYCLES($I)</ncycles>
1      <phase_restrain>$ARPWARP_PHASE_RESTRAIN($I)</phase_restrain>
1      <phase_blur>$ARPWARP_PHASE_BLUR($I)</phase_blur>
1      <damp_p>$ARPWARP_DAMP_P($I)</damp_p>
1      <damp_b>$ARPWARP_DAMP_B($I)</damp_b>
1      <weight_mode>$ARPWARP_WEIGHT_MODE($I)</weight_mode>
1      <wmat>$ARPWARP_WMAT($I)</wmat>
1      <scale>$ARPWARP_SCALE($I)</scale>
1      <scanis>$ARPWARP_SCANIS($I)</scanis>
1      <refmac_ref_set>$ARPWARP_REFMAC_REF_SET($I)</refmac_ref_set>
1      <solvent>$ARPWARP_SOLVENT($I)</solvent>
IF { $ARPWARP_COND_DYN($I) }
1      <conditional_dynamics>0</conditional_dynamics>
ELSE
1      <conditional_dynamics>1</conditional_dynamics>
ENDIF
IF { $ARPWARP_LOOPS($I) }
1      <loops>0</loops>
ELSE
1      <loops>1</loops>
ENDIF
1      <twin>$ARPWARP_TWIN($I)</twin>
1      <no_use_pdb>$ARPWARP_NOUSEPDB($I)</no_use_pdb>
1      <tlsonoff>$ARPWARP_TLSONOFF($I)</tlsonoff>
1      <sad_href_occu>$ARPWARP_HREF_OCCU($I)</sad_href_occu>
1      <sad_href_temp>$ARPWARP_SAD_HREF_TEMP($I)</sad_href_temp>
1      <sad_href_coor>$ARPWARP_SAD_HREF_COOR($I)</sad_href_coor>
1   </arpwarp>
ENDIF
