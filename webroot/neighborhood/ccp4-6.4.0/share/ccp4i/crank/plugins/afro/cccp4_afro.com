#		
# AFRO Section (Multivariate E-value calculation)
#
IF { [StringSame $PROGRAM_NAME($I) AFRO] } 
# INPUT
1   <input>
1      <exp_columns>
LOOP K 1 $N_CRYSTALS
1         <crystal id="$K">
IF $CRYSTAL_NATIVE($K)
1	     <data id="1">
1	        <f>$INPUT_EXPERIMENTAL_COLUMNS($I)_X${K}_D1_F</f>
1               <sigf>$INPUT_EXPERIMENTAL_COLUMNS($I)_X${K}_D1_SIGF</sigf>
1		<anomalous>0</anomalous>
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
1   </input>
# OUTPUT
1   <output>
1      <ea_columns>
1          <ea>$OUTPUT_EA_COLUMNS($I)_EA</ea>
1          <sigea>$OUTPUT_EA_COLUMNS($I)_SIGEA</sigea>
1      </ea_columns>
1      <fa_columns>
1          <fa>$OUTPUT_FA_COLUMNS($I)_FA</fa>
1          <sigfa>$OUTPUT_FA_COLUMNS($I)_SIGFA</sigfa>
1      </fa_columns>
1      <alpha_columns>
1         <alpha>$OUTPUT_ALPHA_COLUMNS($I)_ALPHA</alpha>
1      </alpha_columns>
1   </output>
# Afro specific parameters
1   <afro>
1      <lo_res>$AFRO_LOW_RES_CUTOFF($I)</lo_res>
1      <hi_res>$AFRO_HIGH_RES_CUTOFF($I)</hi_res>
1      <manual_reso>$AFRO_MANUAL_RESO($I)</manual_reso>
1      <sigf>$AFRO_SIGF($I)</sigf>
1      <sano>$AFRO_SANO($I)</sano>
1      <manual_sigmas>$AFRO_MANUAL_SIGMAS($I)</manual_sigmas>
1   </afro>
ENDIF
