#
# SHELXC Section
#
IF { [StringSame $PROGRAM_NAME($I) SHELXC] } 
1   <input>
1      <exp_columns>
LOOP K 1 $N_CRYSTALS
1         <crystal id="$K">
IF $CRYSTAL_NATIVE($K)
1            <data id="1">
IF $INPUT_INTENSITY
1               <i>$INPUT_EXPERIMENTAL_COLUMNS($I)_X${K}_D1_I</i>
1               <sigi>$INPUT_EXPERIMENTAL_COLUMNS($I)_X${K}_D1_SIGI</sigi>
ELSE
1               <f>$INPUT_EXPERIMENTAL_COLUMNS($I)_X${K}_D1_F</f>
1               <sigf>$INPUT_EXPERIMENTAL_COLUMNS($I)_X${K}_D1_SIGF</sigf>
ENDIF
1               <anomalous>0</anomalous>
1            </data>
ELSE
LOOP M 1 $N_DATA($K)
1            <data id="$M">
IF $INPUT_INTENSITY
IF $DATA_ANOMALOUS($K,$M)
1               <i_plus>$INPUT_EXPERIMENTAL_COLUMNS($I)_X${K}_D${M}_I+</i_plus>
1               <sigi_plus>$INPUT_EXPERIMENTAL_COLUMNS($I)_X${K}_D${M}_SIGI+</sigi_plus>
1               <i_minus>$INPUT_EXPERIMENTAL_COLUMNS($I)_X${K}_D${M}_I-</i_minus>
1               <sigi_minus>$INPUT_EXPERIMENTAL_COLUMNS($I)_X${K}_D${M}_SIGI-</sigi_minus>
ELSE
1               <i>$INPUT_EXPERIMENTAL_COLUMNS($I)_X${K}_D1_I</i>
1               <sigi>$INPUT_EXPERIMENTAL_COLUMNS($I)_X${K}_D1_SIGI</sigi>
ENDIF
ELSE
IF $DATA_ANOMALOUS($K,$M)
1               <f_plus>$INPUT_EXPERIMENTAL_COLUMNS($I)_X${K}_D${M}_F+</f_plus>
1               <sigf_plus>$INPUT_EXPERIMENTAL_COLUMNS($I)_X${K}_D${M}_SIGF+</sigf_plus>
1               <f_minus>$INPUT_EXPERIMENTAL_COLUMNS($I)_X${K}_D${M}_F-</f_minus>
1               <sigf_minus>$INPUT_EXPERIMENTAL_COLUMNS($I)_X${K}_D${M}_SIGF-</sigf_minus>
ELSE
1               <f>$INPUT_EXPERIMENTAL_COLUMNS($I)_X${K}_D1_F</f>
1               <sigf>$INPUT_EXPERIMENTAL_COLUMNS($I)_X${K}_D1_SIGF</sigf>
ENDIF
ENDIF
1            </data>
ENDLOOP
ENDIF
1         </crystal>
ENDLOOP
1      </exp_columns>
1   </input>
1   <output>
1      <fa_columns>
1         <fa>$OUTPUT_FA_COLUMNS($I)_FA</fa>
1         <sigfa>$OUTPUT_FA_COLUMNS($I)_SIGFA</sigfa>
1      </fa_columns>
1      <ea_columns>
1         <ea>$OUTPUT_FA_COLUMNS($I)_EA</ea>
1         <sigea>$OUTPUT_FA_COLUMNS($I)_SIGEA</sigea>
1      </ea_columns>
IF $INPUT_INTENSITY
1      <i_columns>
1         <i>$OUTPUT_I_COLUMNS($I)_I</i>
1         <sigi>$OUTPUT_I_COLUMNS($I)_SIGI</sigi>
1      </i_columns>
ELSE
1      <f_columns>
1         <f>$OUTPUT_F_COLUMNS($I)_F</f>
1         <sigf>$OUTPUT_F_COLUMNS($I)_SIGF</sigf>
1      </f_columns>
ENDIF
1      <alpha_columns>
1         <alpha>$OUTPUT_ALPHA_COLUMNS($I)_ALPHA</alpha>
1      </alpha_columns>
1   </output>
1   <shelx>
1      <exclude_reso>$SHELXC_EXCLUDE_RESO($I)</exclude_reso>
1      <hi_res>$SHELXC_HIGH_RES_CUTOFF($I)</hi_res>
1   </shelx>
ENDIF
