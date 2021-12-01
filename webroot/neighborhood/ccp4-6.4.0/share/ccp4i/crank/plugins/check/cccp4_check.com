#
# CHECK (VALIDATE WITH KNOWN STRUCTURE)
#
IF { [StringSame $PROGRAM_NAME($I) CHECK] } 
1   <input>
1      <substructure>$INPUT_SUBSTRUCTURE($I)</substructure>
1      <ea_columns>
1         <ea>$INPUT_EA_COLUMNS($I)_EA</ea>
1         <sigea>$INPUT_EA_COLUMNS($I)_SIGEA</sigea>
1      </ea_columns>
1      <fa_columns>
1         <fa>$INPUT_FA_COLUMNS($I)_FA</fa>
1         <sigfa>$INPUT_FA_COLUMNS($I)_SIGFA</sigfa>
1      </fa_columns>
1      <phase_columns>
1          <f>$INPUT_PHASE_COLUMNS($I)_F</f>
1          <sigf>$INPUT_PHASE_COLUMNS($I)_SIGF</sigf>
1          <phib>$INPUT_PHASE_COLUMNS($I)_PHIB</phib>
1          <fom>$INPUT_PHASE_COLUMNS($I)_FOM</fom>
1      </phase_columns>
1      <pdb>$INPUT_PDB($I)</pdb>
1   </input>
1   <check>
1      <final_pdb>$CHECK_PDB($I)</final_pdb>
1   </check>
ENDIF
