# =======================================================================
# phaser_ANO.tcl --
#
# Phaser Anisotropy Analysis
#
# CCP4Interface
#
# =======================================================================

#------------------------------------------------------------------------------
proc phaser_ANO_prereq { } {
#------------------------------------------------------------------------------
  if { ![file exists [FindExecutable phaser]] } {
    return 0
  }
  return 1
}

#------------------------------------------------------------------------
  proc phaser_ANO_setup { typedefVar arrayname } {
#------------------------------------------------------------------------
  upvar #0 $typedefVar typedef
  upvar #0 $arrayname array

  DefineMenu _composition_option \
    [ list "average solvent content for protein crystal" "solvent content of protein crystal" "components in asymmetric unit" ] [ list "AVERAGE" "SOLVENT" "COMPONENT"]

  DefineMenu _protnucleic \
    [list "protein" "nucleic acid" ] [list "PROTEIN" "NUCLEIC" ]

  set typedef(_mwseqnres_option) \
    { menu  { "molecular weight"  "sequence file" "number of residues"} { "MW"  "FASTA" "NRES"} }

  set typedef(_macro_protocol) \
    { menu  { "default" "custom" "fix all" "refine all"} { "DEFAULT" "CUSTOM" "OFF" "ALL"} }

  set typedef(_onoff) \
    { menu { "on" "off" } { ON OFF } }

  return 1
  }

#------------------------------------------------------------------------
proc phaser_ANO_run { arrayname } {
#------------------------------------------------------------------------

  upvar #0 $arrayname array

# The output file array is set up in phaser_ANO.script
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

# Set up the array of input files: 1 or more mtz and maybe some pdb files
  set array(INPUT_FILES) "HKLIN_MAIN"

  if { ([GetValue $arrayname SCATTERING] == "COMPONENT") } {
  for { set n 1 } { $n <= $array(N_COMPONENT) } { incr n } {
    if { $array(COMP_OPTION,$n) == "sequence file" } {
        append array(INPUT_FILES) " COMP_FILE,$n"
     }
   }
   }

  return 1
  }

#------------------------------------------------------------------------
 proc phaser_ANO_component { arrayname counter_component } {
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
 proc phaser_ANO_set_test_space_group { arrayname } {
#------------------------------------------------------------------------
# To set up the choice of test space groups possible (those in the same
#   point group) given the space group from the mtz file
  upvar #0 $arrayname array
  set spgp_list {}
  set spgp_alias {}
  set laue_no [GetLaueGroupNumber $array(FILE_SPACEGROUP)]
# laue_no is zero if FILE_SPACEGROUP is not in the standard list
# update the list of spacegroups varlabel
  phaser_ANO_updatevarlabel $arrayname FILE_SPACEGROUP
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

  set array(PHASER_TEST_SG) [GetSpaceGroupCode $array(FILE_SPACEGROUP)]

}

#------------------------------------------------------------------------
 proc phaser_ANO_updatevarlabel { arrayname FILE_SPACEGROUP } {
#------------------------------------------------------------------------
# procedure to update the FILE_SPACEGROUP varlabel
  upvar #0 $arrayname array
  set field_list [GetWidget $arrayname FILE_SPACEGROUP]
  foreach field $field_list {
    if { [winfo exists $field] } { $field configure -text $array(FILE_SPACEGROUP) } }
  }
#
#------------------------------------------------------------------------
  proc phaser_ANO_set_reso {arrayname} {
#------------------------------------------------------------------------
  upvar #0 $arrayname array
  set array(RESOLUTION_DMIN_MR) [GetValue $arrayname RESOLUTION_DMIN]
  }

#------------------------------------------------------------------------
  proc phaser_ANO_maca { arrayname counter_s } {
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
  proc phaser_ANO_task_window {arrayname} {
#------------------------------------------------------------------------

  upvar #0 $arrayname array
  global configure

  if { [CreateTaskWindow $arrayname \
        "Phaser Anisotropy Analysis"\
        "Phaser" \
        [ list "Define composition of the asymmetric unit" \
               "Output control" \
               "Expert parameters" ] \
       ] == 0 } return

# SetProgramHelpFile phaser


#=PROTOCOL===============================================================

  OpenFolder protocol

  CreateTitleLine line TITLE

# Sets up the central menus for choosing the mode of phaser
#   whether rotation, translation or refinement/rescoring searches

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
        -command "phaser_ANO_set_test_space_group $arrayname" \
        -command "phaser_ANO_set_reso $arrayname"

   CreateLabinLine line \
       "Select amplitude (F) and sigma (SIGF)" \
       HKLIN_MAIN "F" F {NULL} \
       -sigma "SIGF" SIGF {NULL}

  CreateLine line \
      message "Default is to take all data from low resolution limit\
               to the greater of dmin and 2.5 A" \
      widget TOG_RESOLUTION -toggleon \
      label "Resolution range" \
      message "Enter dmax, in Angstroms" \
      widget RESOLUTION_DMAX \
      label "A to" \
      message "If the dataset goes to higher than 2.5 A resolution,\
               then a default dmin of 2.5 A is set." \
      widget RESOLUTION_DMIN_MR \
      label "A"

  CreateLine line \
      message "Space group read from mtz file." \
      label "Space group read from mtz file" \
      varlabel FILE_SPACEGROUP \
      label "; " \

# $line.l2 configure -width 7 -background $configure(COLOUR_BACKGROUND)
#
#========================================================================
# The "Defie composition" folder

  OpenFolder 1 open

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

  CreateExtendingFrame N_COMPONENT phaser_ANO_component \
      "Define another protein or nucleic acid component" "Define another component" \
      [list PROTDNA MW ASYM COMP_OPTION COMP_NRES COMP_FILE DIR_COMP_FILE ]

  CloseSubFrame

#========================================================================
# The "Output control" folder

  OpenFolder 2 closed

  CreateLine line \
      message "VERBOSE: more information included in log file than by default" \
      widget TOG_VERBOSE \
      label "Verbose output to log file" \

  CreateLine line \
      message "DEBUG: debugging information included in log file than by default" \
      widget TOG_DEBUG \
      label "Debug output to log file" 

  CreateLine line \
      message "Controls output of MTZ files with phase information from solutions.\
               Default depends on mode." \
      widget TOG_HKLOUT -toggleon \
      label "MTZ file output" \
      widget HKLOUT_ONOFF

#========================================================================
# The "Expert parameters" folder

  OpenFolder 3 closed

  CreateLine line \
      message "BINS: specify how the binning to all reflections will apply"\
      widget TOG_BINS -toggleon \
      label "Bins: Min" widget BINS_L label "Max" widget BINS_H label "Width" widget BINS_W \
      message "Binning function: AS^3 + BS^2 + CS\
               where S=1/reso. See documentation" \
      label "Cubic: A" widget BINS_A label "B" widget BINS_B label "C" widget BINS_C \
      toggle_display MR_MODE hide [list PAK CCA ]

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
     CreateExtendingFrame N_MACA phaser_ANO_maca \
        "Customize the anisotropic refinement" \
        "Add another anisotropic macrocycle" \
        [list MACA_ANIS MACA_BINS MACA_SOLK MACA_SOLB MACA_NCYC ]
    CloseSubFrame

  CreateLine line \
      message "RESHARPEN: B-factor added back to map coefficients" \
      widget TOG_RESHARPEN -toggleon \
      label "Resharpening percentage " \
      message "Resharpening percentage " \
      widget RESHARPEN_PERC

  }

#use puts to output debugging info to screen
