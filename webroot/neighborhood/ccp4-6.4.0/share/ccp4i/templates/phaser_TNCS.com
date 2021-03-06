1 #---PHASER COMMAND SCRIPT GENERATED BY CCP4I---
{[IfSet $TITLE]} TITLE $TITLE
1 MODE NCS
1 ROOT \\"$OUTPUT_FILE_ROOT\\"

1 #---DEFINE DATA---
1 HKLIN \\"$HKLIN_MAIN\\"
LABELLINE LABIN "F SIGF" 

$TOG_RESOLUTION RESOLUTION HIGH $RESOLUTION_DMIN_MR LOW $RESOLUTION_DMAX

{![StringSame $FILE_SPACEGROUP $TEST_SPACEGROUP] && ![StringSame $TEST_SPACEGROUP ""] } SPACEGROUP $TEST_SPACEGROUP

1 #---DEFINE COMPOSITION---
IF {[StringSame $SCATTERING COMPONENT]}
  1 COMPOSITION BY ASU
ELSE
  1 COMPOSITION BY $SCATTERING
ENDIF
{[StringSame $SCATTERING SOLVENT]} COMPOSITION PERCENTAGE $SCATTERING_SOLVENT
LOOP C 1 $N_COMPONENT
  {[StringSame $SCATTERING COMPONENT] && [StringSame $COMP_OPTION($C) MW ]} COMPOSITION $PROTDNA($C) MW $MW($C) NUMBER $ASYM($C)
  {[StringSame $SCATTERING COMPONENT] && [StringSame $COMP_OPTION($C) FASTA ]} COMPOSITION $PROTDNA($C) SEQ \\"$COMP_FILE($C)\\" NUMBER $ASYM($C)
  {[StringSame $SCATTERING COMPONENT] && [StringSame $COMP_OPTION($C) NRES ]} COMPOSITION $PROTDNA($C) NRES $COMP_NRES($C) NUMBER $ASYM($C)
ENDLOOP

1 #---OUTPUT CONTROL---
{$TOG_VERBOSE} VERBOSE ON
{$TOG_DEBUG} DEBUG ON
{$TOG_HKLOUT} HKLOUT $HKLOUT_ONOFF

1 #---EXPERT PARAMETERS---
{$TOG_ANISO} MACANO PROTOCOL $MACA_PROTOCOL
IF {$TOG_ANISO && [StringSame $MACA_PROTOCOL CUSTOM]}
  LOOP M 1 $N_MACA
    1 MACA ANIS $MACA_ANIS($M) BINS $MACA_BINS($M) SOLK $MACA_SOLK($M) SOLB $MACA_SOLB($M) NCYC $MACA_NCYC($M)
  ENDLOOP
ENDIF
{$TOG_TNCS} MACTNCS PROTOCOL $MACT_PROTOCOL
IF {$TOG_TNCS && [StringSame $MACT_PROTOCOL CUSTOM]}
  LOOP M 1 $N_MACT
    1 MACT ROT $MACT_ROT($M) TRA $MACT_TRA($M) VAR $MACT_VAR($M) NCYC $MACT_NCYC($M)
  ENDLOOP
ENDIF
{$TOG_BINS && [IfSet $BINS_L]} BINS MIN $BINS_L 
{$TOG_BINS && [IfSet $BINS_H]} BINS MAX $BINS_H 
{$TOG_BINS && [IfSet $BINS_W]} BINS WIDTH $BINS_W 
{$TOG_BINS && [IfSet $BINS_A] && [IfSet $BINS_B] && [IfSet $BINS_C]} BINS CUBIC $BINS_A $BINS_B $BINS_C
{$TOG_RESHARPEN && [IfSet $RESHARPEN_PERC]} RESHARPEN PERC $RESHARPEN_PERC
{$TOG_CELL} CELL $CELL_1 $CELL_2 $CELL_3 $CELL_4 $CELL_5 $CELL_6
{$TOG_OUTLIER && [StringSame $OUTLIER_OPTION OFF] } OUTLIER REJECT OFF
{$TOG_OUTLIER && [StringSame $OUTLIER_OPTION ON] && ![IfSet $OUTLIER_PROB] } OUTLIER REJECT ON
{$TOG_OUTLIER && [StringSame $OUTLIER_OPTION ON] && [IfSet $OUTLIER_PROB] } OUTLIER REJECT ON PROBABILITY $OUTLIER_PROB

{$TOG_TNCS_NMOL && [IfSet $TNCS_NMOL]} TNCS NMOL $TNCS_NMOL 
{$TOG_TNCS_TRA_VECTOR && [IfSet $TNCS_TRA_VECTOR_X] && [IfSet $TNCS_TRA_VECTOR_Y] && [IfSet $TNCS_TRA_VECTOR_Z]} TNCS TRANSLATION VECTOR $TNCS_TRA_VECTOR_X $TNCS_TRA_VECTOR_Y $TNCS_TRA_VECTOR_Z
{$TOG_TNCS_ROT_GRID && [IfSet $TNCS_ROT_GRID]} TNCS ROTATION GRID $TNCS_ROT_GRID 
{$TOG_TNCS_ROT_ANGLE && [IfSet $TNCS_ROT_ANGLE_X] && [IfSet $TNCS_ROT_ANGLE_Y] && [IfSet $TNCS_ROT_ANGLE_Z]} TNCS ROTATION ANGLE $TNCS_ROT_ANGLE_X $TNCS_ROT_ANGLE_Y $TNCS_ROT_ANGLE_Z
{$TOG_TNCS_REFI_ROT && [IfSet $TNCS_REFI_ROT]} TNCS REFINE ROTATION $TNCS_REFI_ROT 
{$TOG_TNCS_ROT_RANGE && [IfSet $TNCS_ROT_RANGE]} TNCS ROT RANGE $TNCS_ROT_RANGE 
{$TOG_TNCS_ROT_SAMPLING && [IfSet $TNCS_ROT_SAMPLING]} TNCS ROT SAMPLING $TNCS_ROT_SAMPLING 
{$TOG_TNCS_VAR_RMSD && [IfSet $TNCS_VAR_RMSD]} TNCS VAR RMSD $TNCS_VAR_RMSD 
{$TOG_TNCS_VAR_FRAC && [IfSet $TNCS_VAR_FRAC]} TNCS VAR FRAC $TNCS_VAR_FRAC 
{$TOG_TNCS_PATT_RESO && [IfSet $TNCS_PATT_HIRES]} TNCS PATT HIRES $TNCS_PATT_HIRES 
{$TOG_TNCS_PATT_RESO && [IfSet $TNCS_PATT_LORES]} TNCS PATT LORES $TNCS_PATT_LORES 
{$TOG_TNCS_PATT_PERCENT && [IfSet $TNCS_PATT_PERCENT]} TNCS PATT PERCENT $TNCS_PATT_PERCENT 
{$TOG_TNCS_PATT_DISTANCE && [IfSet $TNCS_PATT_DISTANCE]} TNCS PATT DISTANCE $TNCS_PATT_DISTANCE 
