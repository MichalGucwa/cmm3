#
# PIRATE Section (Density modification)
#
IF { [StringSame $PROGRAM_NAME($I) PIRATE] } 
1   <input>
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
1     </exp_columns>
1     <hl_columns>
1        <hla>$INPUT_HL_COLUMNS($I)_HLA</hla>
1        <hlb>$INPUT_HL_COLUMNS($I)_HLB</hlb>
1        <hlc>$INPUT_HL_COLUMNS($I)_HLC</hlc>
1        <hld>$INPUT_HL_COLUMNS($I)_HLD</hld>
1     </hl_columns>
1     <freer_columns>
1        <freer>$INPUT_FREER_COLUMNS($I)_FREER</freer>
1     </freer_columns>
1 </input>
1 <output>
1    <phase_columns>
1       <f>$OUTPUT_PHASE_COLUMNS($I)_F</f>
1       <sigf>$OUTPUT_PHASE_COLUMNS($I)_SIGF</sigf>
1       <phib>$OUTPUT_PHASE_COLUMNS($I)_PHIB</phib>
1       <fom>$OUTPUT_PHASE_COLUMNS($I)_FOM</fom>
1    </phase_columns>
1    <hl_columns>
1       <hla>$OUTPUT_HL_COLUMNS($I)_HLA</hla>
1       <hlb>$OUTPUT_HL_COLUMNS($I)_HLB</hlb>
1       <hlc>$OUTPUT_HL_COLUMNS($I)_HLC</hlc>
1       <hld>$OUTPUT_HL_COLUMNS($I)_HLD</hld>
1    </hl_columns>
1 </output>
1 <pirate>
1    <determine_hand>$PIRATE_HAND($I)</determine_hand>
1    <optimize_solvent>$PIRATE_OPT($I)</optimize_solvent>
1    <density_modify>$PIRATE_DENMOD($I)</density_modify>
1    <hlphasing_coefficients>$PIRATE_HLOUTPUT($I)</hlphasing_coefficients>
1    <use_ncs>$PIRATE_USENCS($I)</use_ncs>
1    <ncycles>$PIRATE_NCYCLES($I)</ncycles>
1    <inweight>$PIRATE_INPUTWEIGHT($I)</inweight>
1    <auto_content>$PIRATE_AUTOCONTENT($I)</auto_content>
1    <auto_weight>$PIRATE_AUTOWEIGHT($I)</auto_weight>
1 </pirate>
ENDIF