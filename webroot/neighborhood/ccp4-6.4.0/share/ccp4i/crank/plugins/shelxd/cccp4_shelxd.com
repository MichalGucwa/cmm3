#
# SHELXD Section (Direct methods for substructure determination)
#
IF { [StringSame $PROGRAM_NAME($I) SHELXD] } 
1   <input>
1      <fa_columns>
1         <fa>$INPUT_FA_COLUMNS($I)_FA</fa>
1         <sigfa>$INPUT_FA_COLUMNS($I)_SIGFA</sigfa>
1      </fa_columns>
1      <alpha_columns>
1         <alpha>$INPUT_ALPHA_COLUMNS($I)_ALPHA</alpha>
1      </alpha_columns>
1   </input>
1   <output>
1      <substructure>$PROGRAM_TAG($I)</substructure>
1   </output>
# SHELXD specific parameters
1   <shelx>
1      <dsul>$SHELXD_DSUL($I)</dsul>
1      <mind>$SHELXD_MIND($I)</mind>
1      <mdeq>$SHELXD_MDEQ($I)</mdeq>
1      <ntry>$SHELXD_NUM_TRIALS($I)</ntry>
1      <ccweak_threshold>$SHELXD_CCWEAK_THRESHOLD($I)</ccweak_threshold>
1      <min_trials>$SHELXD_MIN_TRIALS($I)</min_trials>
1      <lo_res>$SHELXD_LOW_RES_CUTOFF($I)</lo_res>
IF  $SHELXD_EXCLUDE_RESO($I) 
1      <hi_res>$SHELXD_HIGH_RES_CUTOFF($I)</hi_res>
ENDIF
1      <pats>$SHELXD_PATS($I)</pats>
1      <weed>$SHELXD_WEED($I)</weed>
1   </shelx>
ENDIF
