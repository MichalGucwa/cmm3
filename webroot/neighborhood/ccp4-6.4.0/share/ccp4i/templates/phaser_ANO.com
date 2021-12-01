1 #---PHASER COMMAND SCRIPT GENERATED BY CCP4I---
{[IfSet $TITLE]} TITLE $TITLE
1 MODE ANO
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
{$TOG_BINS && [IfSet $BINS_L]} BINS MIN $BINS_L 
{$TOG_BINS && [IfSet $BINS_H]} BINS MAX $BINS_H 
{$TOG_BINS && [IfSet $BINS_W]} BINS WIDTH $BINS_W 
{$TOG_BINS && [IfSet $BINS_A] && [IfSet $BINS_B] && [IfSet $BINS_C]} BINS CUBIC $BINS_A $BINS_B $BINS_C
{$TOG_RESHARPEN && [IfSet $RESHARPEN_PERC]} RESHARPEN PERC $RESHARPEN_PERC
{$TOG_CELL} CELL $CELL_1 $CELL_2 $CELL_3 $CELL_4 $CELL_5 $CELL_6
ENDIF