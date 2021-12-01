#
# SOLOMON Section (Density modification)
#
IF { [StringSame $PROGRAM_NAME($I) SOLOMON] } 
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
1      </exp_columns>
1      <hl_columns>
1         <hla>$INPUT_HL_COLUMNS($I)_HLA</hla>
1         <hlb>$INPUT_HL_COLUMNS($I)_HLB</hlb>
1         <hlc>$INPUT_HL_COLUMNS($I)_HLC</hlc>
1         <hld>$INPUT_HL_COLUMNS($I)_HLD</hld>
1      </hl_columns>
1   </input>
1   <output>
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
1   <solomon>
1      <ncycles>$SOLOMON_NCYCLES($I)</ncycles>
1      <hand_cycles>$SOLOMON_HCYCLES($I)</hand_cycles>
1      <opt_cycles>$SOLOMON_OCYCLES($I)</opt_cycles>
1      <trunc_low>$SOLOMON_TRUNC_LOW($I)</trunc_low>
1      <trunc_high>$SOLOMON_TRUNC_HIGH($I)</trunc_high>
1      <radius>$SOLOMON_RADIUS($I)</radius>
1      <margin>$SOLOMON_MARGIN($I)</margin>
1      <hlphasing_coefficients>$SOLOMON_HLOUTPUT($I)</hlphasing_coefficients>
IF { $SOLOMON_HAND($I) }
1      <no_hand>0</no_hand>
ELSE
1      <no_hand>1</no_hand>
ENDIF
IF { $SOLOMON_BIAS($I) }
1      <bias>0</bias>
ELSE
1      <bias>1</bias>
ENDIF
1      <beta>$SOLOMON_BETA($I)</beta>
1      <optimize_solvent>$SOLOMON_OPT($I)</optimize_solvent>
1      <density_modify>$SOLOMON_DENMOD($I)</density_modify>
1      <keep_mtz>$SOLOMON_KEEPMTZ($I)</keep_mtz>
1      <phase_comb>$SOLOMON_PHASE_COMB($I)</phase_comb>
1   </solomon>
ENDIF
