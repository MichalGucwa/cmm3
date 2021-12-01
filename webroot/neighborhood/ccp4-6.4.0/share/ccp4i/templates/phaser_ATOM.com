1 #---PHASER COMMAND SCRIPT GENERATED BY CCP4I---
{[IfSet $TITLE]} TITLE $TITLE
1 MODE MR_ATOM
1 ROOT \\"$OUTPUT_FILE_ROOT\\"
$TOG_NJOBS JOBS $NJOBS

1 #---DEFINE DATA---
1 HKLIN \\"$HKLIN_MAIN\\"
LABELLINE LABIN "F SIGF" 

$TOG_RESOLUTION RESOLUTION HIGH $RESOLUTION_DMIN_MR LOW $RESOLUTION_DMAX

IF {$TOG_SPACEGROUP }
  {![StringSame $FILE_SPACEGROUP $TEST_SPACEGROUP] && ![StringSame $TEST_SPACEGROUP ""] } SPACEGROUP $TEST_SPACEGROUP
ENDIF

{[StringSame $SPACEGROUP_OPTION SG_MTZ]} SGALTERNATIVE SELECT NONE
{[StringSame $SPACEGROUP_OPTION SG_ALT]} SGALTERNATIVE SELECT LIST
{[StringSame $SPACEGROUP_OPTION SG_ALT]} SGALTERNATIVE TEST $PHASER_TEST_SG

1 #---DEFINE SEARCH---
1 ENSEMBLE SINGLEATOM ATOM $SEARCH_ATOM_TYPE
1 SEARCH ENSEMBLE SINGLEATOM NUMBER $SEARCH_ATOM_NUM

IF {$TOG_LLGC && [StringSame $LLGC_COMPLETE OFF]}
  1 LLGCOMPLETE COMPLETE OFF
ENDIF
IF {$TOG_LLGC && [StringSame $LLGC_COMPLETE ON]}
  {![StringSame $LLGC_FIRST_TYPE ""]} LLGCOMPLETE SCATTERER $LLGC_FIRST_TYPE
  LOOP J 1 $N_LLGC
    {$TOG_LLGC_ATOM && ![StringSame $LLGC_TYPE($J) ""]} LLGCOMPLETE SCATTERER $LLGC_TYPE($J)
  ENDLOOP
ENDIF
{$TOG_LLGC_CLASH && [StringSame $LLGC_CLASH_DEFAULT OFF] } LLGCOMPLETE CLASH  $LLGC_CLASH_DISTANCE
{$TOG_LLGC_SIGMA} LLGCOMPLETE SIGMA  $LLGC_SIGMA
{$TOG_LLGC_NCYC } LLGCOMPLETE NCYC   $LLGC_NCYC

1 #---DEFINE COMPOSITION---
IF {![StringSame $MR_MODE PAK]}
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
ENDIF

1 #---SEARCH PARAMETERS---

{$TOG_SEARCH_METHOD} SEARCH METHOD $SEARCH_METHOD
{$TOG_SEARCH_METHOD && [StringSame $SEARCH_METHOD FAST]} SEARCH DEEP $SEARCH_DEEP
{$TOG_SEARCH_METHOD && [StringSame $SEARCH_METHOD FAST]} SEARCH DOWN PERCENT $SEARCH_DOWN_PERC

1 #---EXPERT PARAMETERS---

IF {[StringSame $MR_MODE AUTO ROT]}
  {[IfSet $SET_SOL_FILE_NOTOB]} @ \\"$SET_SOL_FILE_NOTOB\\"
ENDIF

{$TOG_PACK && ![StringSame $PACK_OPTION ALL] } PACK SELECT $PACK_OPTION CUTOFF $PACK_ALLOWED_CLASHES 
{$TOG_PACK && [StringSame $PACK_OPTION ALL] } PACK SELECT ALL 
{$TOG_PACK_QUICK} PACK QUICK $PACK_QUICK_ONOFF 

{$TOG_FINAL_TRA && [IfSet $FINAL_SIGMA_TRA] && ![StringSame $FINAL_OPTION_TRA ALL]} PEAKS TRA SELECT $FINAL_OPTION_TRA CUTOFF $FINAL_SIGMA_TRA
{$TOG_FINAL_TRA && [StringSame $FINAL_OPTION_TRA ALL]} PEAKS TRA SELECT ALL
{$TOG_PEAKS_TRA_CLUSTER} PEAKS TRA CLUSTER $PEAKS_TRA_CLUSTER
{$TOG_PURGE_TRA} PURGE TRA ENABLE $PURGE_TRA_ONOFF
{$TOG_PURGE_TRA && [StringSame $PURGE_TRA_ONOFF ON] && [IfSet $PURGE_TRA_PERCENT]} PURGE TRA PERCENT $PURGE_TRA_PERCENT
{$TOG_PURGE_TRA && [StringSame $PURGE_TRA_ONOFF ON] && [IfSet $PURGE_TRA_NUMBER ]} PURGE TRA NUMBER  $PURGE_TRA_NUMBER 

IF {[StringSame $SEARCH_METHOD FULL]}
  {$TOG_SEARCH_METHOD} PERMUTATIONS $PERMUTATIONS_ONOFF
ENDIF

{$TOG_RESOLUTION_AUTO} RESOLUTION AUTO HIGH $RESOLUTION_AUTO_DMIN LOW $RESOLUTION_AUTO_DMAX

{$TOG_TNCS_USE} TNCS USE $TNCS_USE
IF {[StringSame $TNCS_USE ON]}
  {$TOG_TNCS_NMOL && [IfSet $TNCS_NMOL]} TNCS NMOL $TNCS_NMOL 
  {$TOG_TNCS_TRA_VECTOR && [IfSet $TNCS_TRA_VECTOR_X] && [IfSet $TNCS_TRA_VECTOR_Y] && [IfSet $TNCS_TRA_VECTOR_Z]} TNCS TRANSLATION VECTOR $TNCS_TRA_VECTOR_X $TNCS_TRA_VECTOR_Y $TNCS_TRA_VECTOR_Z
  {$TOG_TNCS_PATT_PERCENT && [IfSet $TNCS_PATT_PERCENT]} TNCS PATT PERCENT $TNCS_PATT_PERCENT 
ENDIF

1 #---OUTPUT CONTROL---
{$TOG_VERBOSE} VERBOSE ON
{$TOG_VERBOSE_EXTRA} DEBUG ON
{$TOG_KEYWDS} KEYWORDS $KEYWDS_ONOFF
{$TOG_XYZOUT} XYZOUT $XYZOUT_ONOFF
{$TOG_TOPF} TOPFILES $XYZOUT_NPDB
{$TOG_HKLOUT} HKLOUT $HKLOUT_ONOFF
{$TOG_LLGC_MAPS } LLGMAPS $LLGC_MAPS

1 #---DEVELOPER PARAMETERS---

IF {[StringSame $MR_MODE_SELECT MR_AUTO MR_FTF] }
  {$TOG_RESCORE_TRA && ![StringSame $RESCORE_ONOFF_TRA NOT_SET]} RESCORE TRA $RESCORE_ONOFF_TRA
  {$TOG_FTF_TARGET} TARGET FTF $FTF_TARGET_OPTION
ENDIF

{$TOG_ANISO} MACANO PROTOCOL $MACA_PROTOCOL
IF {$TOG_ANISO && [StringSame $MACA_PROTOCOL CUSTOM]}
LOOP M 1 $N_MACA
  1 MACA ANIS $MACA_ANIS($M) BINS $MACA_BINS($M) SOLK $MACA_SOLK($M) SOLB $MACA_SOLB($M) NCYC $MACA_NCYC($M)
ENDLOOP
ENDIF

{$TOG_CELL} CELL $CELL_1 $CELL_2 $CELL_3 $CELL_4 $CELL_5 $CELL_6

{$TOG_PACK_DISTANCE} PACK DISTANCE $PACK_DISTANCE 
{$TOG_PACK_TRACE} PACK TRACE $PACK_TRACE 
{$TOG_PACK_COMPACT} PACK COMPACT $PACK_COMPACT_ONOFF

{$TOG_MACM} MACMR PROTOCOL $MACM_PROTOCOL
IF {$TOG_MACM && [StringSame $MACM_PROTOCOL CUSTOM]} 
LOOP M 1 $N_MACM
  1 MACMR ROT $MACM_ROT($M) TRA $MACM_TRA($M) BFAC $MACM_BFAC($M) VRMS $MACM_VRMS($M) LAST $MACM_LAST($M) NCYC $MACM_NCYC($M)
ENDLOOP
ENDIF

{$TOG_ZSCORE && [StringSame $SEARCH_METHOD FAST]} ZSCORE USE $ZSCORE_USE 
{$TOG_ZSCORE && [StringSame $SEARCH_METHOD FAST]} ZSCORE SOLVED $ZSCORE_SOLVED 
{$TOG_ZSCORE && [StringSame $SEARCH_METHOD FAST]} ZSCORE HALF $ZSCORE_HALF 
{$TOG_ELLG} ELLG USE $USE_ELLG 
{$TOG_ELLG && [StringSame $USE_ELLG ON] && [IfSet $ELLG_TARGET]} ELLG TARGET $ELLG_TARGET 

IF {[StringSame $TNCS_USE ON]}
  {$TOG_TNCS_ROT_GRID && [IfSet $TNCS_ROT_GRID]} TNCS ROTATION GRID $TNCS_ROT_GRID 
  {$TOG_TNCS_ROT_ANGLE && [IfSet $TNCS_ROT_ANGLE_X] && [IfSet $TNCS_ROT_ANGLE_Y] && [IfSet $TNCS_ROT_ANGLE_Z]} TNCS ROTATION ANGLE $TNCS_ROT_ANGLE_X $TNCS_ROT_ANGLE_Y $TNCS_ROT_ANGLE_Z
  {$TOG_TNCS_REFI_ROT && [IfSet $TNCS_REFI_ROT]} TNCS REFINE ROTATION $TNCS_REFI_ROT 
  {$TOG_TNCS_ROT_RANGE && [IfSet $TNCS_ROT_RANGE]} TNCS ROT RANGE $TNCS_ROT_RANGE 
  {$TOG_TNCS_ROT_SAMPLING && [IfSet $TNCS_ROT_SAMPLING]} TNCS ROT SAMPLING $TNCS_ROT_SAMPLING 
  {$TOG_TNCS_VAR_RMSD && [IfSet $TNCS_VAR_RMSD]} TNCS VAR RMSD $TNCS_VAR_RMSD 
  {$TOG_TNCS_VAR_FRAC && [IfSet $TNCS_VAR_FRAC]} TNCS VAR FRAC $TNCS_VAR_FRAC 
  {$TOG_TNCS_PATT_RESO && [IfSet $TNCS_PATT_HIRES]} TNCS PATT HIRES $TNCS_PATT_HIRES 
  {$TOG_TNCS_PATT_RESO && [IfSet $TNCS_PATT_LORES]} TNCS PATT LORES $TNCS_PATT_LORES 
  {$TOG_TNCS_PATT_DISTANCE && [IfSet $TNCS_PATT_DISTANCE]} TNCS PATT DISTANCE $TNCS_PATT_DISTANCE 
ENDIF

