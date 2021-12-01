#
# SHELXE Section
#
IF { [StringSame $PROGRAM_NAME($I) SHELXE] } 
1   <input>
1      <substructure>$INPUT_SUBSTRUCTURE($I)</substructure>
IF $INPUT_INTENSITY
1         <i_columns>
1            <i>$INPUT_I_COLUMNS($I)_I</i>
1            <sigi>$INPUT_I_COLUMNS($I)_SIGI</sigi>
1         </i_columns>
ELSE
1         <f_columns>
1            <f>$INPUT_F_COLUMNS($I)_F</f>
1            <sigf>$INPUT_F_COLUMNS($I)_SIGF</sigf>
1         </f_columns>
ENDIF
1         <fa_columns>
1            <fa>$INPUT_FA_COLUMNS($I)_FA</fa>
1            <sigfa>$INPUT_FA_COLUMNS($I)_SIGFA</sigfa>
1         </fa_columns>
1         <alpha_columns>
1            <alpha>$INPUT_ALPHA_COLUMNS($I)_ALPHA</alpha>
1         </alpha_columns>
IF { SHELXE_INPUT_PHASES($I) }
1         <phase_columns>
1            <f>$OUTPUT_PHASE_COLUMNS($I)_F</f>
1            <sigf>$OUTPUT_PHASE_COLUMNS($I)_SIGF</sigf>
1            <phib>$OUTPUT_PHASE_COLUMNS($I)_PHIB</phib>
1            <fom>$OUTPUT_PHASE_COLUMNS($I)_FOM</fom>
1         </phase_columns>
ENDIF
1   </input>
1   <output>
#1      <pdb>$PROGRAM_TAG($I)</pdb>
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
1      <substructure>$OUTPUT_SUBSTRUCTURE($I)</substructure>
1   </output>
# SHELXE specific parameters
1   <shelxe>
1      <ncycles>$SHELXE_NCYCLES($I)</ncycles>
1      <hand_cycles>$SHELXE_HCYCLES($I)</hand_cycles>
1      <opt_cycles>$SHELXE_OCYCLES($I)</opt_cycles>
1      <no_hand>!$SHELXE_HAND($I)</no_hand>
1      <optimize_solvent>$SHELXE_OPT($I)</optimize_solvent>
1      <density_modify>$SHELXE_DENMOD($I)</density_modify>
1      <model_build>$SHELXE_MODELBUILD($I)</model_build>
1      <generate_heavy>$SHELXE_GENERATE_HEAVY($I)</generate_heavy>
1      <free_lunch>$SHELXE_FREE_LUNCH($I)</free_lunch>
1      <free_lunch_reso>$SHELXE_FREE_LUNCH_RESO($I)</free_lunch_reso>
1   </shelxe>
ENDIF
