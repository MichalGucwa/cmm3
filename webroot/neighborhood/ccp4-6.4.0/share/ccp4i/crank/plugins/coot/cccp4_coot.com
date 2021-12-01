#
# COOT Section (Model/Map visualization)
#
IF { [StringSame $PROGRAM_NAME($I) COOT] } 
1   <input>
1      <substructure>$INPUT_SUBSTRUCTURE($I)</substructure>
1      <pdb>$INPUT_PDB($I)</pdb>
1    <phase_columns>
1       <f>$INPUT_PHASE_COLUMNS($I)_F</f>
1       <sigf>$INPUT_PHASE_COLUMNS($I)_SIGF</sigf>
1       <phib>$INPUT_PHASE_COLUMNS($I)_PHIB</phib>
1       <fom>$INPUT_PHASE_COLUMNS($I)_FOM</fom>
1    </phase_columns>
1     <freer_columns>
1        <freer>$INPUT_FREER_COLUMNS($I)_FREER</freer>
1     </freer_columns>
1    <pdb>$INPUT_PDB($I)</pdb>
1 </input>
1 <coot>
1    <map>$COOT_MAP($I)</map>
1    <pdb>$COOT_PDB($I)</pdb>
1    <substructure>$COOT_SUBSTRUCTURE($I)</substructure> 
1 </coot>
ENDIF
