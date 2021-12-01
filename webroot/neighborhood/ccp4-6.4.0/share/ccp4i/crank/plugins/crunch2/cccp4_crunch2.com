#
# CRUNCH2 Section (Direct methods for substructure solution)
#
IF { [StringSame $PROGRAM_NAME($I) CRUNCH2] } 
1   <input>
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
1      <ea_columns>
1         <ea>$INPUT_EA_COLUMNS($I)_EA</ea>
1         <sigea>$INPUT_EA_COLUMNS($I)_SIGEA</sigea>
1      </ea_columns>
1      <fa_columns>
1         <fa>$INPUT_FA_COLUMNS($I)_FA</fa>
1         <sigfa>$INPUT_FA_COLUMNS($I)_SIGFA</sigfa>
1      </fa_columns>
1   </input>
1   <output>
1      <substructure>$PROGRAM_TAG($I)</substructure>
1   </output>
# Crunch2 specific parameters
1   <crunch2>
IF { $CRUNCH2_PATT_TRIALS($I) > 0 }
1      <patt_search>1</patt_search>
ELSE
1      <patt_search>0</patt_search>
ENDIF
1      <patt_trials>$CRUNCH2_PATT_TRIALS($I)</patt_trials>
1      <score_threshold>$CRUNCH2_SCORE_THRESHOLD($I)</score_threshold>
1      <deviation>$CRUNCH2_DEVIATION($I)</deviation>
1      <bp3_verify>$CRUNCH2_BP3_VERIFY($I)</bp3_verify>
1      <scattering_power>15</scattering_power>
1      <min_atoms>3</min_atoms>
1      <ntrials>$CRUNCH2_TRIALS($I)</ntrials>
1      <ncycles>$CRUNCH2_NUM_CYCLES($I)</ncycles>
1      <spec>$CRUNCH2_SPECIAL_POSITIONS($I)</spec>
1   </crunch2>
ENDIF
