###################
# PREP Section    #
###################

IF { [StringSame $PROGRAM_NAME($I) PREP] } 
#
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
#
1      <exp_columns>
LOOP K 1 $N_CRYSTALS
1         <crystal id="$K">
IF $CRYSTAL_NATIVE($K)
1            <data id="1">
1               <f>$OUTPUT_EXPERIMENTAL_COLUMNS($I)_X${K}_D1_F</f>
1               <sigf>$OUTPUT_EXPERIMENTAL_COLUMNS($I)_X${K}_D1_SIGF</sigf>
IF $INPUT_INTENSITY  
1               <i>$OUTPUT_EXPERIMENTAL_COLUMNS($I)_X${K}_D1_I</i>
1               <sigi>$OUTPUT_EXPERIMENTAL_COLUMNS($I)_X${K}_D1_SIGI</sigi>
ENDIF
1               <anomalous>0</anomalous>
1            </data>
ELSE
LOOP M 1 $N_DATA($K)
1            <data id="$M">
1               <f>$OUTPUT_EXPERIMENTAL_COLUMNS($I)_X${K}_D${M}_F</f>
1	        <sigf>$OUTPUT_EXPERIMENTAL_COLUMNS($I)_X${K}_D${M}_SIGF</sigf>
IF $DATA_ANOMALOUS($K,$M)
1	        <f_plus>$OUTPUT_EXPERIMENTAL_COLUMNS($I)_X${K}_D${M}_F+</f_plus>
1               <sigf_plus>$OUTPUT_EXPERIMENTAL_COLUMNS($I)_X${K}_D${M}_SIGF+</sigf_plus>
1               <f_minus>$OUTPUT_EXPERIMENTAL_COLUMNS($I)_X${K}_D${M}_F-</f_minus>
1               <sigf_minus>$OUTPUT_EXPERIMENTAL_COLUMNS($I)_X${K}_D${M}_SIGF-</sigf_minus>
IF $INPUT_INTENSITY
1               <i_plus>$OUTPUT_EXPERIMENTAL_COLUMNS($I)_X${K}_D${M}_I+</i_plus>
1               <sigi_plus>$OUTPUT_EXPERIMENTAL_COLUMNS($I)_X${K}_D${M}_SIGI+</sigi_plus>
1               <i_minus>$OUTPUT_EXPERIMENTAL_COLUMNS($I)_X${K}_D${M}_I-</i_minus>
1               <sigi_minus>$OUTPUT_EXPERIMENTAL_COLUMNS($I)_X${K}_D${M}_SIGI-</sigi_minus>
ENDIF
ELSE
IF $INPUT_INTENSITY
1               <i>$OUTPUT_EXPERIMENTAL_COLUMNS($I)_X${K}_D${M}_I</i>
1               <sigi>$OUTPUT_EXPERIMENTAL_COLUMNS($I)_X${K}_D${M}_SIGI</sigi>
ENDIF
ENDIF
1            </data>
ENDLOOP
ENDIF
1         </crystal>
ENDLOOP
1      </exp_columns>
1      <freer_columns>
1         <freer>$OUTPUT_FREER_COLUMNS($I)_FREER</freer>
1      </freer_columns>
1   </output>
1   <prep>
1      <input_rfree>$INPUT_RFREE</input_rfree>
1      <rfree_label>$RFREE_LABEL</rfree_label>
1      <rescale_f>$PREP_RESCALE_F($I)</rescale_f>
1      <rfree_fraction>$RFREE_FRACTION</rfree_fraction>
1      <ncyc>$PREP_CONVERGE_NCYC_LIMIT($I)</ncyc>
1      <lores>$PREP_EXCLUDE_RESOLUTION_LO($I)</lores>
1      <hires>$PREP_EXCLUDE_RESOLUTION_HI($I)</hires>
1      <mode>$PREP_REFINE_MODE($I)</mode>
1      <wilson>$PREP_WILSON_SCALING($I)</wilson>
1      <weight>$PREP_WEIGHT_BY_SD($I)</weight>
1   </prep>
ENDIF
