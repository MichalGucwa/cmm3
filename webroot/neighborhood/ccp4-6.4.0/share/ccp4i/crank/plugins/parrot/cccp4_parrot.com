#
# PARROT Section (Density modification)
#
IF { [StringSame $PROGRAM_NAME($I) PARROT] } 
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
1 <parrot>
IF { $PARROT_BIAS($I) }
1    <bias>0</bias>
ELSE
1    <bias>1</bias>
ENDIF
IF { $PARROT_NOSOLVENT($I) }
1    <solvent_flatten>0</solvent_flatten>
ELSE
1    <solvent_flatten>1</solvent_flatten>
ENDIF
IF { $PARROT_NOHISTOGRAM($I) }
1    <histogram>0</histogram>
ELSE
1    <histogram>1</histogram>
ENDIF
IF { $PARROT_NONCS($I) }
1    <use_ncs>0</use_ncs>
ELSE
1    <use_ncs>1</use_ncs>
ENDIF
1    <hlphasing_coefficients>$PARROT_HLOUTPUT($I)</hlphasing_coefficients>
1    <ncycles>$PARROT_NCYCLES($I)</ncycles>
1    <phase_comb>$PARROT_PHASE_COMB($I)</phase_comb>
1    <keep_mtz>$PARROT_KEEPMTZ($I)</keep_mtz>
1 </parrot>
ENDIF
