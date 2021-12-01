#
# REFMAC Section (Substructure refinement and phasing)
#
IF { [StringSame $PROGRAM_NAME($I) REFMAC] } 
1   <input>
1      <pdb>$INPUT_PDB($I)</pdb>
1      <substructure>$INPUT_SUBSTRUCTURE($I)</substructure>
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
1               <f>$INPUT_EXPERIMENTAL_COLUMNS($I)_X${K}_D${M}_F</f>
1               <sigf>$INPUT_EXPERIMENTAL_COLUMNS($I)_X${K}_D${M}_SIGF</sigf>
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
1      <freer_columns>
1         <freer>$INPUT_FREER_COLUMNS($I)_FREER</freer>
1      </freer_columns>
1   </input>
1   <output>
1      <pdb>$PROGRAM_TAG($I)</pdb>
1      <substructure>$PROGRAM_TAG($I)</substructure>
1      <phase_columns>
1         <f>$OUTPUT_PHASE_COLUMNS($I)_F</f>
1         <sigf>$OUTPUT_PHASE_COLUMNS($I)_SIGF</sigf>
1         <phib>$OUTPUT_PHASE_COLUMNS($I)_PHIB</phib>
1         <fom>$OUTPUT_PHASE_COLUMNS($I)_FOM</fom>
1      </phase_columns>
1      <hl_columns>
1         <hla>$OUTPUT_HL_COLUMNS($I)_HLA</hla>
1         <hlb>$OUTPUT_HL_COLUMNS($I)_HLB</hlb>
1         <hlc>$OUTPUT_HL_COLUMNS($I)_HLC</hlc>
1         <hld>$OUTPUT_HL_COLUMNS($I)_HLD</hld>
1      </hl_columns>
1   </output>
1   <refmac>
1      <mode>$REFMAC_MODE($I)</mode>
1      <no_hand>$REFMAC_NOHAND($I)</no_hand>
1      <target>$REFMAC_TARGET($I)</target>
1      <exclude_freer>$REFMAC_EXCLUDE_FREER($I)</exclude_freer>
1      <cycles>$REFMAC_CYCLES($I)</cycles>
1      <solvent>$REFMAC_SOLVENT($I)</solvent>
1      <stop_fom>$REFMAC_STOP_FOM($I)</stop_fom>
1      <noref_xyz>$REFMAC_XYZNREF($I)</noref_xyz>
1      <noref_occ>$REFMAC_OCCUNREF($I)</noref_occ>
1      <noref_bfac>$REFMAC_BFACNREF($I)</noref_bfac>
1   </refmac>
ENDIF
