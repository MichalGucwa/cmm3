# =======================================================================
# phaser_ATOM.tcl --
#
# Maximum Likelihood Molecular Replacement
#
# CCP4Interface
#
# =======================================================================

#------------------------------------------------------------------------------
proc phaser_ATOM_prereq { } {
#------------------------------------------------------------------------------
  if { ![file exists [FindExecutable phaser]] } {
    return 0
  }
  return 1
}

#------------------------------------------------------------------------
  proc phaser_ATOM_setup { typedefVar arrayname } {
#------------------------------------------------------------------------
  upvar #0 $typedefVar typedef
  upvar #0 $arrayname array

  DefineMenu _spacegroup_option \
    [list "mtz space group"  "alternative spacegroup"] \
    [list "SG_MTZ" "SG_ALT" ]

  set typedef(_laue_space_group) { varmenu LAUE_SPGP_LIST LAUE_SPGP_ALIAS 8 }

  DefineMenu _composition_option \
    [ list "average solvent content for protein crystal" "solvent content of protein crystal" "components in asymmetric unit" ] \
    [ list "AVERAGE" "SOLVENT" "COMPONENT" ]

  DefineMenu _protnucleic \
    [list "protein" "nucleic acid" ] [list "PROTEIN" "NUCLEIC" ]

  DefineMenu _rmsid_option \
   [list "rms difference" "sequence identity" ] [list "RMS" "IDENT" ]

  set typedef(_mwseqnres_option) \
    { menu  { "molecular weight"  "sequence file" "number of residues"} { "MW"  "FASTA" "NRES"} }

  DefineMenu _search_method \
    [list "full" "fast" ] [list "FULL" "FAST" ]

  DefineMenu _llgc_complete \
    [list "on" "off" ] [list "ON" "OFF" ]

  DefineMenu _packing_option \
    [list "best packing (up to percent)" "best packing (up to number)" "max number of clashes" "accept all solutions" ] \
    [list "PERCENT" "BEST" "ALLOWED" "ALL"]

  set typedef(_peaks_option) \
   { menu  { "percentage of top peak" "sigma (Z-score) cutoff" "number of peaks" "all peaks"} \
           { "PERCENT" "SIGMA" "NUMBER" "ALL" } }
  set typedef(_macro_protocol) \
    { menu  { "default" "custom" "fix all" "refine all"} { "DEFAULT" "CUSTOM" "OFF" "ALL"} }
  set typedef(_onoff) \
    { menu { "on" "off" } { ON OFF } }
  set typedef(_tribool) \
    { menu { "on" "off" "auto" } { ON OFF NOT_SET } }
  set typedef(_coord_option) \
    { menu { "orthogonal" "fractional" } { "ORTH" "FRAC" } }

  return 1
  }

#------------------------------------------------------------------------
proc phaser_ATOM_run { arrayname } {
#------------------------------------------------------------------------

  upvar #0 $arrayname array

# The output file array is set up in phaser_ATOM.script
  set array(OUTPUT_FILES) ""

# All output files with the user specified root will be saved to the project dir
#set array(FILENAME_ROOT) [FileJoin [GetDefaultDirPath] $array(ROOT) ]

  if { $array(HKLIN_MAIN) == "" } {
     WarningMessage "NOT SET: mtz reflection data file"
     return 0
  }

  if { ([GetValue $arrayname SCATTERING] == "COMPONENT") } {
  for { set n 1 } { $n <= $array(N_COMPONENT) } { incr n } {
    if { $array(COMP_OPTION,$n) == "sequence file" &&  $array(COMP_FILE,$n) == "" } {
       WarningMessage "NOT SET: sequence file for component # $n"
       return 0
     }
    if { $array(COMP_OPTION,$n) == "molecular weight" &&  $array(MW,$n) == "" } {
       WarningMessage "NOT SET: molecular weight for component # $n"
       return 0
     }
   } }

  if { ([GetValue $arrayname SCATTERING] == "NRES")} { 
    if { ([GetValue $arrayname COMP_NRES] == "")} { 
     WarningMessage "NOT SET: number of residues in the composition"
     return 0
    } }

  if { ([GetValue $arrayname SCATTERING] == "SOLVENT")} { 
    if { ([GetValue $arrayname SCATTERING_SOLVENT] == "")} { 
     WarningMessage "NOT SET: solvent content in the composition"
     return 0
  } }

  if { ([GetValue $arrayname SCATTERING] == "COMPONENT") } {
  for { set n 1 } { $n <= $array(N_COMPONENT) } { incr n } {
    if { $array(COMP_OPTION,$n) == "sequence file" } {
        append array(INPUT_FILES) " COMP_FILE,$n"
     }
   }
   }
#
#LLG completion checks

  if { ([GetValue $arrayname TOG_LLGC] == "1") } {
  if { ([GetValue $arrayname LLGC_COMPLETE] == "ON") } {
  if { ([GetValue $arrayname LLGC_FIRST_TYPE] == "") } {
     WarningMessage "NOT SET: Completion atom type (array empty)"
     return 0
  }
  for { set n 1 } { $n <= $array(N_LLGC) } { incr n } {
    if { ($array(LLGC_TYPE,$n) == "") } {
     WarningMessage "NOT SET: Completion atom type"
     return 0
  } } } }


# Set up the array of input files: 1 or more mtz and maybe some pdb files
  set array(INPUT_FILES) "HKLIN_MAIN"

# If a test space group other than mtz file one has been selected, then extract its space group number.
  if { ![StringSame $array(FILE_SPACEGROUP) \
              [GetValue $arrayname TEST_SPACEGROUP] ] } {
    set array(SPACGROUP_NUMBER) [GetSpaceGroupNumber $array(TEST_SPACEGROUP)]
} else {
    set array(SPACGROUP_NUMBER) ""
  }

  return 1
  }

#------------------------------------------------------------------------
 proc phaser_ATOM_sg { arrayname counter_sg } {
#------------------------------------------------------------------------
  upvar #0 $arrayname array
  CreateLine line \
      label "Test space group #$counter_sg" \
      message "Select a test SG (same point group)\
               or ALL to test all.\
               NB mtz SG will NOT now be tested by default."\
      widget PHASER_TEST_SG 
}

#------------------------------------------------------------------------
 proc phaser_ATOM_component { arrayname counter_component } {
#------------------------------------------------------------------------
# The contents of the "Composition" folder, extending frame 
  upvar #0 $arrayname array

  CreateLine line \
      message "Select for protein or DNA/RNA as a component of the asymmetric unit" \
      label "Component #$counter_component" \
      widget PROTDNA \
      message "Enter the molecular weight of protein/nucleic acid #$counter_component" \
      label "" \
      widget COMP_OPTION -oblig \
      widget MW -oblig \
      message "Enter the number of copies of component #$counter_component in the asu " \
      label "Number in asymmetric unit" \
      widget ASYM -oblig \
     toggle_display COMP_OPTION,$counter_component open MW hide

  CreateLine line \
      message "Select for protein or DNA/RNA as a component of the asymmetric unit" \
      label "Component $counter_component" \
      widget PROTDNA \
      message "Enter the file containing sequence in single letter code or fasta format" \
      label "" \
      widget COMP_OPTION -oblig \
      message "Enter the number of copies of component $counter_component in the asu" \
      label "Number in asymmetric unit" \
      widget ASYM -oblig \
     toggle_display COMP_OPTION,$counter_component open FASTA hide

  CreateInputFileLine line \
      "Select the sequence file" "SEQ file" COMP_FILE DIR_COMP_FILE \
     -toggle_display COMP_OPTION,$counter_component open FASTA hide

  CreateLine line \
      message "Select for protein or DNA/RNA as a component of the asymmetric unit" \
      label "Component $counter_component" \
      widget PROTDNA \
      message "Enter the number of residues of protein/nucleic acid $counter_component" \
      label "" \
      widget COMP_OPTION -oblig \
      widget COMP_NRES -oblig \
      message "Enter the number of copies of component $counter_component in the asymmetric unit" \
      label "Number in asymmetric unit" \
      widget ASYM -oblig \
     toggle_display COMP_OPTION,$counter_component open NRES hide

  }

#------------------------------------------------------------------------
 proc phaser_ATOM_set_test_space_group { arrayname } {
#------------------------------------------------------------------------
# To set up the choice of test space groups possible (those in the same
#   point group) given the space group from the mtz file
  upvar #0 $arrayname array
  set spgp_list {}
  set spgp_alias {}
  set laue_no [GetLaueGroupNumber $array(FILE_SPACEGROUP)]
# laue_no is zero if FILE_SPACEGROUP is not in the standard list
# update the list of spacegroups varlabel
  phaser_ATOM_updatevarlabel $arrayname FILE_SPACEGROUP
  if { $laue_no <= 0 } {
    lappend spgp_list $array(FILE_SPACEGROUP)
    lappend spgp_alias [GetSpaceGroupNumber $array(FILE_SPACEGROUP)]
  } else {
    set spgp_alias [GetLaueGroup $laue_no]
    foreach gp_no $spgp_alias {
      lappend spgp_list [GetSpaceGroupCode $gp_no]
    }
  }
# GetLaueGroup returns a list of space groups for the given Laue Group

  UpdateVariableMenu $arrayname initialise [llength $array(LAUE_SPGP_LIST)] \
        LAUE_SPGP_LIST $spgp_list \
        MODEL_ALIAS_LIST $spgp_alias

  set array(PHASER_TEST_SG) [GetSpaceGroupCode $array(FILE_SPACEGROUP)]

}

#------------------------------------------------------------------------
 proc phaser_ATOM_updatevarlabel { arrayname FILE_SPACEGROUP } {
#------------------------------------------------------------------------
# procedure to update the FILE_SPACEGROUP varlabel
  upvar #0 $arrayname array
  set field_list [GetWidget $arrayname FILE_SPACEGROUP]
  foreach field $field_list {
    if { [winfo exists $field] } { $field configure -text $array(FILE_SPACEGROUP) } }
  }

#------------------------------------------------------------------------
  proc phaser_ATOM_tncs_use_and_valid {arrayname} {
#------------------------------------------------------------------------
  upvar #0 $arrayname array
  set array(TNCS_USE_AND_VALID) "1"
  if { [StringSame $array(TNCS_USE) OFF] } {
    set array(TNCS_USE_AND_VALID) "0"
  }

  }


#------------------------------------------------------------------------
  proc phaser_ATOM_set_reso {arrayname} {
#------------------------------------------------------------------------
  upvar #0 $arrayname array
  set array(RESOLUTION_DMIN_MR) [GetValue $arrayname RESOLUTION_DMIN]
}

#------------------------------------------------------------------------
 proc phaser_ATOM_llgc {  arrayname counter_f } {
#------------------------------------------------------------------------
# Procedure to define a scattering for  atom manually
  upvar #0 $arrayname array
  CreateLineTemplate BB { 0 0.32 0.57 }
  CreateLine line \
      message "Atomtypes for LLG-maps" \
      label "" label "or with atom type" \
      widget LLGC_TYPE \
         -command "phaser_ATOM_llgc_sad_toggle_update $arrayname " \
      format template BB
  }
#

#------------------------------------------------------------------------
  proc phaser_ATOM_maca { arrayname counter_s } {
#------------------------------------------------------------------------
  global configure
  upvar #0 $arrayname array
  CreateLine line \
      label "   Anisotropic" \
      widget MACA_ANIS \
      label "Bins" \
      widget MACA_BINS \
      label "SolK" \
      widget MACA_SOLK \
      label "SolB" \
      widget MACA_SOLB \
      label "Number of Cycles" \
      widget MACA_NCYC -width 5 
  }

#------------------------------------------------------------------------
  proc phaser_ATOM_macm { arrayname counter_s } {
#------------------------------------------------------------------------
  global configure
  upvar #0 $arrayname array
  CreateLine line \
      label "   Rot" \
      widget MACM_ROT \
      label "Tran" \
      widget MACM_TRA \
      label "Bfac" \
      widget MACM_BFAC \
      label "Vrms"\
      widget MACM_VRMS \
      label "Last"\
      widget MACM_LAST \
      label "NCYC" \
      widget MACM_NCYC -width 5
  }

#------------------------------------------------------------------------
  proc phaser_ATOM_task_window {arrayname} {
#------------------------------------------------------------------------

  upvar #0 $arrayname array
  global configure

  if { [CreateTaskWindow $arrayname \
        "Maximum Likelihood Single Atom Molecular Replacement"\
        "Phaser" \
        [ list "Define data" \
               "Define search" \
               "Define composition of the asymmetric unit" \
               "Expert parameters" \
               "Output control" \
               "Developer parameters" ] \
       ] == 0 } return

# SetProgramHelpFile phaser


#=PROTOCOL===============================================================

  OpenFolder protocol

  CreateTitleLine line TITLE

# Sets up the central menus for choosing the mode of phaser
#   whether rotation, translation or refinement/rescoring searches

  CreateLine line \
      message "Number of processors (parallelization)" \
      widget TOG_NJOBS -toggleon \
      label "Number of processors "\
      widget NJOBS \
      label "(only relevant if phaser compiled with openmp option)"

#=FILE===================================================================

# The "Define data" folder

  OpenFolder 1 open

  CreateInputFileLine line \
      "Enter MTZ file name (HKLIN)" \
      "MTZ in     " \
      HKLIN_MAIN DIR_HKLIN_MAIN \
        -setfileparam resolution_min RESOLUTION_DMAX \
        -setfileparam resolution_max RESOLUTION_DMIN \
        -setfileparam resolution_min RESOLUTION_AUTO_DMAX \
        -setfileparam resolution_max RESOLUTION_AUTO_DMIN \
        -setfileparam cell_1 CELL_1 \
        -setfileparam cell_2 CELL_2 \
        -setfileparam cell_3 CELL_3 \
        -setfileparam cell_4 CELL_4 \
        -setfileparam cell_5 CELL_5 \
        -setfileparam cell_6 CELL_6 \
        -setfileparam space_group_name FILE_SPACEGROUP \
        -command "phaser_ATOM_set_test_space_group $arrayname" \
        -command "phaser_ATOM_set_reso $arrayname"

   CreateLabinLine line \
       "Select amplitude (F) and sigma (SIGF)" \
       HKLIN_MAIN "F" F {NULL} \
       -sigma "SIGF" SIGF {NULL}

  CreateLine line \
      message "Default is to take all data" \
      widget TOG_RESOLUTION -toggleon \
      label "Resolution range" \
      message "Enter dmax, in Angstroms" \
      widget RESOLUTION_DMAX label "A to" widget RESOLUTION_DMIN_MR label "A"

  CreateLine line \
      message "Space group read from mtz file." \
      label "Space group read from mtz file" \
      varlabel FILE_SPACEGROUP \
      label "; " \
      message "Specify the space group to run Phaser with" \
      label "Run Phaser with" \
      widget SPACEGROUP_OPTION 

  OpenSubFrame frame -toggle_display SPACEGROUP_OPTION open SG_ALT

  CreateLine line \
      label "Space Group:" widget PHASER_TEST_SG 

  CloseSubFrame

# $line.l2 configure -width 7 -background $configure(COLOUR_BACKGROUND)

#========================================================================
# The "Define search" folder

  OpenFolder 2 open

  CreateLine line \
      message "Atom type for which to search" \
      label "Search single atom type" \
      widget SEARCH_ATOM_TYPE -oblig \
      label "Number of atoms " \
      widget SEARCH_ATOM_NUM -oblig 

  CreateLineTemplate AA { 0 0.23 0.32 0.57 }
  CreateLine line \
      widget TOG_LLGC -toggleon \
      label "LLG-map completion" \
      widget LLGC_COMPLETE \
      label "Complete with atom type " \
      widget LLGC_FIRST_TYPE \
      format template AA \
      toggle_display LLGC_COMPLETE open ON hide

  CreateLineTemplate AB { 0 0.23 }
  CreateLine line \
      widget TOG_LLGC -toggleon \
      label "LLG-map completion" \
      widget LLGC_COMPLETE \
      format template AB \
      toggle_display LLGC_COMPLETE open OFF hide

  OpenSubFrame frame -toggle_display LLGC_COMPLETE open ON hide

  CreateExtendingFrame N_LLGC phaser_ATOM_llgc \
      "Add another atomtype" "Add another atomtype" \
      [list LLGC_TYPE ] 

  CloseSubFrame


  CreateLine line \
      message "Default sigma cut-off = 6" \
      widget TOG_LLGC_SIGMA -toggleon \
      label "LLG-map sigma cut-off for adding new atom sites" \
      widget LLGC_SIGMA

  CreateLine line \
      message "Default clash distance is optical resolution" \
      widget TOG_LLGC_CLASH -toggleon \
      label "LLG-map atomic separation distance cut-off default" \
      widget LLGC_CLASH_DEFAULT \
      toggle_display LLGC_CLASH_DEFAULT open ON

  CreateLine line \
      message "Default clash distance is optical resolution" \
      widget TOG_LLGC_CLASH -toggleon \
      label "LLG-map atomic separation distance cut-off default" \
      widget LLGC_CLASH_DEFAULT \
      label "Distance" \
      widget LLGC_CLASH_DISTANCE \
      toggle_display LLGC_CLASH_DEFAULT open OFF

  CreateLine line \
      widget TOG_LLGC_NCYC -toggleon \
      label "Maximum number of LLG-map completion cycles" \
      widget LLGC_NCYC

#========================================================================
# The "Define composition of the asymmetric unit" folder

  OpenFolder 3 open 

  CreateLine line \
      message "Total scattering of atoms in the asymmetric unit" \
      label "Total scattering determined by "\
      widget SCATTERING \
      toggle_display SCATTERING hide SOLVENT 

  CreateLine line \
      message "Total scattering of atoms in the asymmetric unit" \
      label "Total scattering determined by "\
      widget SCATTERING \
      widget SCATTERING_SOLVENT  -oblig \
      toggle_display SCATTERING open SOLVENT 

  OpenSubFrame frame -toggle_display SCATTERING open COMPONENT hide

  CreateExtendingFrame N_COMPONENT phaser_ATOM_component \
      "Define another protein or nucleic acid component" "Define another component" \
      [list PROTDNA MW ASYM COMP_OPTION COMP_NRES COMP_FILE DIR_COMP_FILE ]

  CloseSubFrame

#========================================================================
# The "Expert parameters" folder

  OpenFolder 4 closed

  CreateInputFileLine line \
      "Define known solutions from a SOL file\
       (Phaser search results file)" \
      "SOL file" \
      SET_SOL_FILE_NOTOB DIR_SET_SOL_FILE_NOTOB \
     -notoblig

  CreateLine line \
       message "Solutions with the lowest number of clashes will be saved \
               if less than the max allowed (default 10)" \
      widget TOG_PACK -toggleon \
      label "Packing criterion " \
      widget PACK_OPTION \
      label "Allow " \
      widget PACK_ALLOWED_CLASHES \
      toggle_display PACK_OPTION open BEST

  CreateLine line \
       message "All solutions will be saved no matter how many clashes" \
      widget TOG_PACK -toggleon \
      label "Packing criterion " \
      widget PACK_OPTION \
      toggle_display PACK_OPTION open ALL

  CreateLine line \
       message "Default for allowed C-alpha clashes is 10;\
                increase for low-homology models" \
      widget TOG_PACK -toggleon \
      label "Packing criterion " \
      widget PACK_OPTION \
      label "Allow " \
      widget PACK_ALLOWED_CLASHES \
      toggle_display PACK_OPTION open ALLOWED

  CreateLine line \
       message "Default for allowed C-alpha clashes is 10;\
                increase for low-homology models" \
      widget TOG_PACK -toggleon \
      label "Packing criterion " \
      widget PACK_OPTION \
      label "Allow " \
      widget PACK_ALLOWED_CLASHES \
      toggle_display PACK_OPTION open PERCENT

  CreateLine line \
      widget TOG_PACK_QUICK -toggleon \
      label "Quick Packing " \
      widget PACK_QUICK_ONOFF \
      toggle_display PACK_OPTION hide ALL

  CreateLine line \
      message "Final selection criterion for peaks from translation searches" \
      widget TOG_FINAL_TRA -toggleon \
      label "Translation search peak selection" \
      message "Default 75 percent" \
      widget FINAL_OPTION_TRA \
      message "Enter the cutoff" \
      widget FINAL_SIGMA_TRA \
      toggle_display FINAL_OPTION_TRA hide [list ALL] open 

  CreateLine line \
      message "Final selection criterion for peaks from translation searches" \
      widget TOG_FINAL_TRA -toggleon \
      label "Translation search peak selection" \
      message "Default 75 percent" \
      widget FINAL_OPTION_TRA \
      toggle_display FINAL_OPTION_TRA open [list ALL] hide 

  CreateLine line \
      message "Choose whether to purge the solutions from TF" \
      widget TOG_PURGE_TRA -toggleon \
      label "Purge translation peaks" \
      widget PURGE_TRA_ONOFF \
      label " percent cutoff" \
      widget PURGE_TRA_PERCENT \
      label "but with maximum number " \
      widget PURGE_TRA_NUMBER \
      toggle_display PURGE_TRA_ONOFF open ON

  CreateLine line \
      message "Choose whether to purge the solutions from TF and RNP \
               (when searching multiple space groups)" \
      widget TOG_PURGE_TRA -toggleon \
      label "Purge translation peaks" \
      widget PURGE_TRA_ONOFF \
      toggle_display PURGE_TRA_ONOFF open OFF

  CreateLine line \
     message "Use FAST if you expect the TFZ to be high for each copy" \
     widget TOG_SEARCH_METHOD -toggleon \
     label "Search method for multiple copies in ASU " \
     widget SEARCH_METHOD \
      message "Choose whether to permute the order of the search set.\
               Default is OFF." \
      label "Permute search set" \
      widget PERMUTATIONS_ONOFF \
     toggle_display SEARCH_METHOD open FULL hide

  CreateLine line \
     message "Use FAST if you expect the TFZ to be high for each copy" \
     widget TOG_SEARCH_METHOD -toggleon \
     label "Search method for multiple copies in ASU " \
     widget SEARCH_METHOD \
     message "Reduce RF peak cutoff on 2nd pass" \
     label "Deep" \
     widget SEARCH_DEEP \
     label "Down percent" \
     message "Value for reducing cutoff" \
     widget SEARCH_DOWN_PERC \
     toggle_display SEARCH_METHOD open FAST hide

  OpenSubFrame frame -toggle_display SEARCH_METHOD open [list FAST]

  CreateLine line \
     message "Controls how TFZ is used in decision making" \
     widget TOG_ZSCORE -toggleon \
     label "Use Z-score (TFZ)" widget ZSCORE_USE \
     label "TFZ solved " widget ZSCORE_SOLVED \
     label "and also half highest" widget ZSCORE_HALF \
     toggle_display ZSCORE_USE open ON hide

  CreateLine line \
     message "Controls how TFZ is used in decision making" \
     widget TOG_ZSCORE -toggleon \
     label "Use Z-score (TFZ)" widget ZSCORE_USE \
     toggle_display ZSCORE_USE open OFF hide

  CloseSubFrame

  CreateLine line \
      message "Target for expected LLG given model completeness and RMS" \
      widget TOG_USE_ELLG -toggleon \
      label "Use \"expected LLG\" criteria in decision making" widget USE_ELLG label " Target LLG " widget ELLG_TARGET \
      toggle_display USE_ELLG open ON hide

  CreateLine line \
      message "Target for expected LLG given model completeness and RMS" \
      widget TOG_USE_ELLG -toggleon \
      label "Use \"expected LLG\" criteria in decision making" widget USE_ELLG \
      toggle_display USE_ELLG open OFF hide

  CreateLine line \
      message "Default is to take all data in mtz file" \
      widget TOG_RESOLUTION_AUTO -toggleon \
      label "Resolution range for high resolution refinement" \
      message "Enter dmax, in Angstroms" \
      widget RESOLUTION_AUTO_DMAX \
      label "A to" \
      widget RESOLUTION_AUTO_DMIN \
      label "A" 

  CreateLine line \
      message "TNCS: use or ignore translational NCS if present" \
      widget TOG_TNCS_USE -toggleon \
      label "Use translational NCS if present " \
      widget TNCS_USE -command "phaser_ATOM_tncs_use_and_valid $arrayname" \
      toggle_display TNCS_USE open ON

  CreateLine line \
      label "TNCS: " \
      widget TOG_TNCS_NMOL -toggleon \
      label "Number of assemblies related by TNCS " \
      widget TNCS_NMOL \
      toggle_display TNCS_USE open ON

  CreateLine line \
      message "TNCS: Parameters for identifying TNCS from Patterson" \
      label "TNCS: " \
      widget TOG_TNCS_PATT_PERCENT -toggleon \
      label "Minimum percent of Patterson origin peak " \
      widget TNCS_PATT_PERCENT \
      toggle_display TNCS_USE open ON

  CreateLine line \
      message "TNCS: translation vector in Angstroms" \
      label "TNCS: " \
      widget TOG_TNCS_TRA_VECTOR -toggleon \
      label "Fix vector " \
      widget TNCS_TRA_VECTOR_X \
      widget TNCS_TRA_VECTOR_Y \
      widget TNCS_TRA_VECTOR_Z label "Angstroms" \
      toggle_display TNCS_USE open ON

  CreateLine line \
      message "TNCS: use or ignore translational NCS if present" \
      widget TOG_TNCS_USE -toggleon \
      label "Use translational NCS if present " \
      widget TNCS_USE -command "phaser_ATOM_tncs_use_and_valid $arrayname" \
      toggle_display TNCS_USE open OFF

#========================================================================
# The "Output control" folder

  OpenFolder 5 closed

  CreateLine line \
      message "VERBOSE: more information included in log file than by default" \
      widget TOG_VERBOSE \
      label "Verbose output to log file" \

  CreateLine line \
      message "DEBUG: debugging information included in log file than by default" \
      widget TOG_VERBOSE_EXTRA \
      label "Debug output to log file" 

  CreateLine line \
      message "Default number of top pdbfiles and mtzfiles is 1" \
      widget TOG_TOPF -toggleon \
      label "Number of top solutions to output as PDB and MTZ files"\
      widget XYZOUT_NPDB

  CreateLine line \
      message "Output the results in a .sol file" \
      widget TOG_KEYWDS -toggleon \
      label "SOL file output" \
      widget KEYWDS_ONOFF

  CreateLine line \
      message "Controls output of PDB files containing potential solutions.\
               Default depends on mode." \
      widget TOG_XYZOUT -toggleon \
      label "PDB file output" \
      widget XYZOUT_ONOFF

  CreateLine line \
      message "Controls output of MTZ files with phase information from solutions.\
               Default depends on mode." \
      widget TOG_HKLOUT -toggleon \
      label "MTZ file output" \
      widget HKLOUT_ONOFF

  CreateLine line \
      message "Controls output of LLG map coefficients to MTZ file" \
      widget TOG_LLGC_MAPS -toggleon \
      label "Output log-likelihood gradient map coefficients" \
      widget LLGC_MAPS

#========================================================================
# The "Developer parameters" folder

  OpenFolder 6 closed

  CreateLine line \
      label "Do not alter these parameters" -italic

  CreateLine line \
      message "Select whether or not to rescore fast search solutions" \
      widget TOG_RESCORE_TRA -toggleon \
      label "Rescoring translation" \
      widget RESCORE_ONOFF_TRA

  CreateLine line \
    widget TOG_CELL -toggleon \
    label "Unit Cell: a" \
    message "Cell dimensions (default from MTZ file) (CELL)" \
    widget CELL_1 -width 8 \
    label "b" \
    widget CELL_2 -width 8 \
    label "c" \
    widget CELL_3 -width 8 \
    label "alpha" \
    widget CELL_4 -width 8 \
    label "beta" \
    widget CELL_5 -width 8 \
    label "gamma" \
    widget CELL_6 -width 8

  CreateLine line \
      message "Refinement macrocyles" \
      widget TOG_ANISO -toggleon \
      label "Anisotropic refinement protocol" \
      widget MACA_PROTOCOL

  OpenSubFrame frame \
    -toggle_display MACA_PROTOCOL open CUSTOM hide
   CreateExtendingFrame N_MACA phaser_ATOM_maca \
      "Customize the anisotropic refinement" \
      "Add another anisotropic macrocycle" \
      [list MACA_ANIS MACA_BINS MACA_SOLK MACA_SOLB MACA_NCYC ]
  CloseSubFrame

  CreateLine line \
      message "Refinement macrocyles" \
      widget TOG_MACM -toggleon \
      label "Molecular replacement refinement protocol" \
      widget MACM_PROTOCOL

  OpenSubFrame frame \
    -toggle_display MACM_PROTOCOL open CUSTOM hide
   CreateExtendingFrame N_MACM phaser_ATOM_macm \
      "Customize the MR refinement" \
      "Add another MR macrocycle" \
      [list MACM_ROT MACM_TRA MACM_BFAC MACM_VRMS MACM_LAST MACM_NCYC ]
  CloseSubFrame

  CreateLine line \
      message "PACKING: sampling of search space" \
      widget TOG_PACK_DISTANCE -toggleon \
      label "Distance for the packing test" \
      message "Distance between marker atoms for the clash test " \
      widget PACK_DISTANCE

  CreateLine line \
      message "PACKING: sampling of search space" \
      widget TOG_PACK_TRACE -toggleon \
      label "Use Trace atom for packing analysis " \
      message "Use C-alphas in proteins, P for RNA/DNA for clash test" \
      widget PACK_TRACE

  CreateLine line \
      widget TOG_PACK_COMPACT -toggleon \
      label "Pack molecules into compact group " \
      widget PACK_COMPACT_ONOFF

  CreateLine line \
      message "Select whether clustered or raw peaks are to be rescored" \
      widget TOG_PEAKS_TRA_CLUSTER -toggleon \
      label "Translation clustering" \
      widget PEAKS_TRA_CLUSTER

  OpenSubFrame frame -toggle_display TNCS_USE_AND_VALID open 1

  CreateLine line \
      message "TNCS: refine TNCS rotation angles starting from sampling grid" \
      label "TNCS: " \
      widget TOG_TNCS_ROT_GRID -toggleon \
      label "Refine TNCS rotation starting from angles on a grid " \
      widget TNCS_ROT_GRID

  CreateLine line \
      message "TNCS: rotation angle in degrees, perturbations around X Y and Z" \
      label "TNCS: " \
      widget TOG_TNCS_ROT_ANGLE -toggleon \
      label "Initial TNCS rotation " \
      widget TNCS_ROT_ANGLE_X \
      widget TNCS_ROT_ANGLE_Y \
      widget TNCS_ROT_ANGLE_Z label "Degrees (XYZ perturbations)" \
      toggle_display TNCS_ROT_GRID open ON 

  CreateLine line \
      message "TNCS: rotation range" \
      label "TNCS: " \
      widget TOG_TNCS_ROT_RANGE -toggleon \
      label "Range of angles to sample to find initial TNCS rotation " \
      widget TNCS_ROT_RANGE \
      label "Degrees" \
      toggle_display TNCS_ROT_GRID open ON 

  CreateLine line \
      message "TNCS: rotation range" \
      label "TNCS: " \
      widget TOG_TNCS_ROT_SAMPLING -toggleon \
      label "Sampling of angles to find initial TNCS rotation " \
      widget TNCS_ROT_SAMPLING \
      label "Degrees" \
      toggle_display TNCS_ROT_GRID open ON 

  CreateLine line \
      message "TNCS: rotation angle in degrees, perturbations around X Y and Z" \
      label "TNCS: " \
      widget TOG_TNCS_ROT_ANGLE -toggleon \
      label "Fixed rotation between TNCS related molecules " \
      widget TNCS_ROT_ANGLE_X \
      widget TNCS_ROT_ANGLE_Y \
      widget TNCS_ROT_ANGLE_Z label "Degrees" \
      toggle_display TNCS_ROT_GRID open OFF

  CreateLine line \
      message "TNCS: Number of molecules/assemblies related by TNCS vector" \
      label "TNCS: " \
      widget TOG_TNCS_NMOL -toggleon \
      label "Number of molecules/assemblies related by TNCS " \
      widget TNCS_NMOL

  CreateLine line \
      message "TNCS: refine rotation angles" \
      label "TNCS: " \
      widget TOG_TNCS_REFI_ROT -toggleon \
      label "Refine TNCS rotations prior to translation function " \
      widget TNCS_REFI_ROT

  CreateLine line \
      message "TNCS: RMSD between TNCS related molecules" \
      label "TNCS: " \
      widget TOG_TNCS_VAR_RMSD -toggleon \
      label "RMSD between TNCS related molecules " \
      widget TNCS_VAR_RMSD \
      label "Angstroms"

  CreateLine line \
      message "TNCS: Fraction of asymmetric unit obeying TNCS" \
      label "TNCS: " \
      widget TOG_TNCS_VAR_FRAC -toggleon \
      label "Fraction of asymmetric unit obeying TNCS " \
      widget TNCS_VAR_FRAC

  CreateLine line \
      message "TNCS: Parameters for identifying TNCS from Patterson" \
      label "TNCS: " \
      widget TOG_TNCS_PATT_RESO -toggleon \
      label "Patterson high resolution " \
      widget TNCS_PATT_HIRES \
      label "low resolution " \
      widget TNCS_PATT_LORES

  CreateLine line \
      message "TNCS: Parameters for identifying TNCS from Patterson" \
      label "TNCS: " \
      widget TOG_TNCS_PATT_DISTANCE -toggleon \
      label "Minimum length of TNCS vector " \
      widget TNCS_PATT_DISTANCE

  CloseSubFrame

  }

#use puts to output debugging info to screen
