
# ensembler.tcl --
#
# Molecular replacement model improvement
#
# CCP4Interface
#
# =======================================================================

#------------------------------------------------------------------------------
proc ensembler_prereq { } {
#------------------------------------------------------------------------------
  if { ![file exists [FindExecutable phaser.ensembler]] } {
    return 0
  }
  return 1
}

#------------------------------------------------------------------------
proc ensembler_setup { typedefVar arrayname } {
#------------------------------------------------------------------------
  upvar #0 $typedefVar typedef
  upvar #0 $arrayname array

  DefineMenu _output_style \
    [ list "Merged" "Separate" ] \
    [ list "merged" "separate" ]

  DefineMenu _output_sort \
    [ list "by input order" "by weighted rmsd" "by unweighted rmsd" \
        "by sequence identity" "by sequence overlap" ] \
    [ list "input" "wrmsd" "unwrmsd" "identity" "overlap" ]

  DefineMenu _config_superposition_method \
    [ list "gapless" "gapped" ] \
    [ list "gapless" "gapped" ]

  DefineMenu _config_mapping \
    [ list "ssm" "alignments" "resid" "multiple_alignment" ] \
    [ list "ssm" "alignments" "resid" "multiple_alignment" ]

  DefineMenu _config_weighting_scheme \
    [ list "unit" "robust_resistant" ] \
    [ list "unit" "robust_resistant" ]

  return 1
  }

#------------------------------------------------------------------------
proc ensembler_run { arrayname } {
#------------------------------------------------------------------------

  upvar #0 $arrayname array

  if { $array(NPDBINS) == 0 } {
    WarningMessage "No PDB files specified"
    return 0
  }

  set ali_based_mappings [ list "alignments" "multiple_alignment" ]
  set is_ali_based_mapping [ expr { [ lsearch -exact $ali_based_mappings $array(CONFIG_MAPPING) ] >= 0 } ]
  set no_alignments_specified [ expr { $array(NALIGNMENTS) == 0 } ]

  if { $is_ali_based_mapping && $no_alignments_specified } {
    WarningMessage "No alignments specified, and mapping by alignment requested"
    return 0
  }

  set array(INPUT_FILES) ""
  
  for { set n 1 } { $n <= $array(NPDBINS) } { incr n } {
    append array(INPUT_FILES) "PDBIN,$n "
  }

  for { set n 1 } { $n <= $array(NALIGNMENTS) } { incr n } {
    append array(INPUT_FILES) "ALNIN,$n "
  }

  return 1
  }

#------------------------------------------------------------------------
proc ensembler_add_pdb { arrayname counter } {
#------------------------------------------------------------------------
  
  upvar #0 $arrayname array

  CreateInputFileLine line \
    "Enter input structure file name" \
    "Structure in" \
    PDBIN DIR_PDBIN \
    -oblig
  }

#------------------------------------------------------------------------
proc ensembler_add_alignment { arrayname counter } {
#------------------------------------------------------------------------
  
  upvar #0 $arrayname array

  CreateInputFileLine line \
    "Enter input alignment file name" \
    "Alignment in" \
    ALNIN DIR_ALNIN \
    -oblig
  }

#------------------------------------------------------------------------
proc ensembler_add_atom_name { arrayname counter } {
#------------------------------------------------------------------------
  
  upvar #0 $arrayname array

   CreateLine line \
     message "Enter atom name" \
     label "Atom name" \
     widget CONFIG_ATOM_NAME \
     -oblig
  }

#------------------------------------------------------------------------
  proc ensembler_task_window { arrayname } {
#------------------------------------------------------------------------
  upvar #0 $arrayname array
  global configure

  if { [ CreateTaskWindow $arrayname \
        "Molecular Replacement Model Improvement"\
        "Ensembler" \
        [ list "General" "Configuration" ] \
        ] == 0 } return

#=FILE===================================================================

  OpenFolder file
  CreateLine line label "Superpose chains in:"

  CreateExtendingFrame NPDBINS ensembler_add_pdb \
    "Structures to use" \
    "Add structure" \
    [ list PDBIN DIR_PDBIN ]

  CreateLine line label "Use alignments:"

  CreateExtendingFrame NALIGNMENTS ensembler_add_alignment \
    "Alignments to use" \
    "Add alignment" \
    [ list ALNIN DIR_ALNIN ]


#========================================================================
# General options folder

  OpenFolder 1

  CreateLine line label "Superposition method" widget CONFIG_SUPERPOSITION_METHOD
  CreateLine line label "Mapping method" widget CONFIG_MAPPING
  CreateLine line label "Weighting scheme" widget CONFIG_WEIGHTING_SCHEME
  CreateLine line label "Trim ensemble" widget CONFIG_TRIM
  CreateLine line label "Output" widget OUTPUT_STYLE

#========================================================================
# Configurations folder
  OpenFolder 2
  
  CreateLine line label "Superposition convergence:" widget CONFIG_SUPERPOSITION_CONVERGENCE
  CreateLine line label "Weighting convergence:" widget CONFIG_WEIGHTING_CONVERGENCE
  CreateLine line label "Weighting incremental damping factor:" widget CONFIG_WEIGHTING_DAMPING_INCR
  CreateLine line label "Weighting max damping factor:" widget CONFIG_WEIGHTING_DAMPING_MAX
  CreateLine line label "Clustering distance:" widget CONFIG_CLUSTERING
  
  CreateExtendingFrame CONFIG_NATOMS ensembler_add_atom_name \
    "Use atom in superposition" \
    "Add atom name" \
    [ list CONFIG_ATOM_NAME ]

  OpenSubFrame frame -toggle_display CONFIG_WEIGHTING_SCHEME open { "robust_resistant" }
  CreateLine line label "Robust-resistant critical value:" widget CONFIG_WEIGHTING_RR_CRITICAL
  CloseSubFrame
  
  OpenSubFrame frame -toggle_display CONFIG_TRIM open 1
  CreateLine line label "Trimming threshold:" widget CONFIG_TRIMMING_THRESHOLD
  CloseSubFrame
 }

