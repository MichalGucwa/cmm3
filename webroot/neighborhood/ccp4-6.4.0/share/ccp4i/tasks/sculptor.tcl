
# sculptor.tcl --
#
# Molecular replacement model improvement
#
# CCP4Interface
#
# =======================================================================

#------------------------------------------------------------------------------
proc sculptor_prereq { } {
#------------------------------------------------------------------------------
  if { ![file exists [FindExecutable phaser.sculptor]] } {
    return 0
  }
  return 1
}

#------------------------------------------------------------------------
proc sculptor_setup { typedefVar arrayname } {
#------------------------------------------------------------------------
  upvar #0 $typedefVar typedef
  upvar #0 $arrayname array

  DefineMenu _sculptor_mode \
    [ list "Predefined protocols" "User-defined protocol" ] \
    [ list "PREDEFINED" "NEW" ]

  DefineMenu _sculptor_protocol \
    [ list "protocol1" "protocol2" "protocol3" "protocol4" "protocol5" \
        "protocol6" "protocol7" "protocol8" "protocol9" "protocol10" \
        "protocol11" "protocol12" "protocol13" ] \
    [ list "1" "2" "3" "4" "5" "6" "7" "8" "9" "10" "11" "12" "13" ]

  DefineMenu _renumber_mode \
    [ list "target sequence" "model sequence" "no renumbering" ] \
    [ list "target" "model" "original" ]

  DefineMenu _scoring_matrix \
    [ list "blosum50" "blosum62" "dayhoff" "identity" ] \
    [ list "blosum50" "blosum62" "dayhoff" "identity" ]

  DefineMenu _weighting_scheme \
    [ list "triangular" "uniform" ] \
    [ list "triangular" "uniform" ]

  DefineMenu _protocol_mode \
    [ list "Use all protocols" "Specify individual protocols" ] \
    [ list 1 0 ]

  return 1
  }

#------------------------------------------------------------------------
proc sculptor_run { arrayname } {
#------------------------------------------------------------------------

  upvar #0 $arrayname array

  if { [ string equal [ GetValue $arrayname SCULPTOR_MODE ] "NEW" ] == 1 } {
    
    if { $array(USE_PRUNING_SIM) } {
      if { $array(PRUNING_SIM_UPPER) < $array(PRUNING_SIM_LOWER) } {
        WarningMessage \
          "Upper threshold below lower threshold in similarity-based pruning"
        return 0
      }
    }
    
    if { $array(USE_BFACTOR_ASA) == 1 } {
      if { $array(BFACTOR_ASA_CALC_PRECISION) < 1 } {
        WarningMessage "Non-positive precision for ASA calculation"
        return 0
      }
    }
  }
  
  set array(INPUT_FILES) ""
  append array(INPUT_FILES) "PDBIN "

  for { set n 1 } { $n <= $array(NALIGNMENTS) } { incr n } {
  append array(INPUT_FILES) "ALNIN,$n "
  }

  return 1
  }

#------------------------------------------------------------------------
proc sculptor_use_protocol { arrayname counter } {
#------------------------------------------------------------------------

  upvar #0 $arrayname array

   CreateLine line \
     message "Protocol to use" \
     label "Use" \
     widget PROTOCOL
  }

#------------------------------------------------------------------------
proc sculptor_use_alignment { arrayname counter } {
#------------------------------------------------------------------------
  
  upvar #0 $arrayname array

  CreateInputFileLine line \
    "Enter input alignment file name" \
    "Alignment in" \
    ALNIN DIR_ALNIN \
    -oblig
  }

#------------------------------------------------------------------------
proc sculptor_add_hetero { arrayname counter } {
#------------------------------------------------------------------------
  
  upvar #0 $arrayname array

   CreateLine line \
     message "Enter residue name" \
     label "Residue name" \
     widget HETERO \
     -oblig
  }

#------------------------------------------------------------------------
proc sculptor_similarity_calculation { arrayname root } {
#------------------------------------------------------------------------
  
  upvar #0 $arrayname array

  CreateLine line label "Similarity calculation:"
  CreateLine line label "    Scoring matrix" \
    widget [ format {%s_CALC_MATRIX} $root ]
  
  CreateLine line label "    Averaging window" \
    widget [ format {%s_CALC_WINDOW} $root ] \
    -oblig
  
  CreateLine line label "    Weighting scheme" \
    widget [ format {%s_CALC_WEIGHTING} $root ]
  }

#------------------------------------------------------------------------
proc sculptor_asa_calculation { arrayname root } {
#------------------------------------------------------------------------
  
  upvar #0 $arrayname array

  CreateLine line label "Accessible surface area calculation:"
  CreateLine line label "    Precision:" \
    widget [ format {%s_CALC_PRECISION} $root ] \
    -oblig
  
  CreateLine line label "    Probe radius:" \
    widget [ format {%s_CALC_RADIUS} $root ] \
    -oblig
  }

#------------------------------------------------------------------------
  proc sculptor_task_window { arrayname } {
#------------------------------------------------------------------------
  upvar #0 $arrayname array
  global configure

  if { [CreateTaskWindow $arrayname \
        "Molecular Replacement Model Improvement"\
        "Sculptor" \
        [ list "General" "Use protocols" "Mainchain editing algorithms" \
          "Sidechain editing algorithms" "Bfactor editing algorithms" ] \
        ] == 0 } return

#=PROTOCOL===============================================================

  OpenFolder protocol

  CreateTitleLine line TITLE
  CreateLine line label "Run Sculptor using" widget SCULPTOR_MODE


#=FILE===================================================================

  OpenFolder file
  CreateInputFileLine line \
    "Enter input PDB file name" \
    "PDB in" \
    PDBIN DIR_PDBIN \
    -oblig

  CreateLine line label "Use alignments:"

  CreateExtendingFrame NALIGNMENTS sculptor_use_alignment \
      "Alignments to use" \
      "Add alignment" \
      [ list ALNIN DIR_ALNIN ]


#========================================================================
# General options folder

  OpenFolder 1

  CreateLine line label "Renumber according to" widget RENUMBER_MODE
  CreateLine line label "Rename residues" widget RENAME_MODE
  CreateLine line label "Keep hetero residues:"
  CreateExtendingFrame NHETEROS sculptor_add_hetero \
      "Keep hetero residue" \
      "Add residue name" \
      [ list HETERO ]

#========================================================================
# Use protocols folder

  OpenFolder 2 SCULPTOR_MODE open [ list "PREDEFINED" ] hide

  CreateLine line widget USE_ALL_PROTOCOLS

  OpenSubFrame frame -toggle_display USE_ALL_PROTOCOLS open 0 hide
  CreateExtendingFrame NPROTOCOLS sculptor_use_protocol \
      "Protocols to use" \
      "Add protocol" \
      [ list PROTOCOL ]
  CloseSubFrame

#========================================================================
# Mainchain editing folder

  OpenFolder 3 SCULPTOR_MODE open [ list "NEW" ] hide

  CreateLine line label "Deletion algorithms"

  CreateLine line widget USE_DELETION_GAP label "Gap"
  
  CreateLine line \
    widget USE_DELETION_COMP \
    label "Sequence similarity with target completeness"
  OpenSubFrame frame -toggle_display USE_DELETION_COMP open 1 hide
  CreateLine line \
    label "Target completeness wrt Schwarzenbacher-algorithm" \
    widget DELETION_COMP_COMPLETENESS
  sculptor_similarity_calculation array DELETION_COMP
  CloseSubFrame

  CreateLine line \
    widget USE_DELETION_THR \
    label "Sequence similarity with threshold"
  OpenSubFrame frame -toggle_display USE_DELETION_THR open 1 hide
  CreateLine line \
    label "Acceptance threshold" \
    widget DELETION_THR_THRESHOLD
  sculptor_similarity_calculation array DELETION_THR
  CloseSubFrame

  CreateLine line label "Polishing algorithms:"
  
  CreateLine line widget USE_POLISHING_RS label "Remove short segments"
  CreateLine line label "Minimum length:" widget POLISHING_RS_MIN -oblig \
    toggle_display USE_POLISHING_RS open 1
  
  CreateLine line widget USE_POLISHING_KR \
    label "Keep regular secondary structure"
  CreateLine line label "Maximum restore length:" \
    widget POLISHING_KR_MAX -oblig \
    toggle_display USE_POLISHING_KR open 1
#========================================================================
# Sidechain editing folder

  OpenFolder 4 SCULPTOR_MODE open [ list "NEW" ] hide
  
  CreateLine line label "Pruning algorithms"

  CreateLine line widget USE_PRUNING_SCH label "Residue type-based"
  CreateLine line label "Pruning level:" \
    widget PRUNING_SCH_LEVEL -oblig \
    toggle_display USE_PRUNING_SCH open 1
  
  CreateLine line \
    widget USE_PRUNING_SIM \
    label "Sequence similarity-based"
  OpenSubFrame frame -toggle_display USE_PRUNING_SIM open 1 hide
  CreateLine line label "Pruning level:" widget PRUNING_SIM_LEVEL
  CreateLine line label "Full-length limit:" widget PRUNING_SIM_UPPER
  CreateLine line label "Full truncation limit:" widget PRUNING_SIM_LOWER
  sculptor_similarity_calculation array PRUNING_SIM
  CloseSubFrame

  CreateLine line label "Completion algorithms"
  CreateLine line widget USE_CBETA label "Add missing Cbeta"

#========================================================================
# Bfactor editing folder

  OpenFolder 5 SCULPTOR_MODE open [ list "NEW" ] hide

  CreateLine line label "Minimum B-value:" widget BFACTOR_MINIMUM -oblig

  CreateLine line widget USE_BFACTOR_ORIGINAL label "Original B-factors"
  CreateLine line label "Multiplicator:" \
    widget BFACTOR_ORIGINAL_FACTOR \
    toggle_display USE_BFACTOR_ORIGINAL open 1

  CreateLine line \
    widget USE_BFACTOR_SIM \
    label "Sequence similarity-based"
  OpenSubFrame frame -toggle_display USE_BFACTOR_SIM open 1 hide
  CreateLine line label "Multiplicator:" widget BFACTOR_SIM_FACTOR
  sculptor_similarity_calculation array BFACTOR_SIM
  CloseSubFrame
  
  CreateLine line \
    widget USE_BFACTOR_ASA \
    label "Accessible surface area-based"
  OpenSubFrame frame -toggle_display USE_BFACTOR_ASA open 1 hide
  CreateLine line label "Multiplicator:" widget BFACTOR_ASA_FACTOR
  sculptor_asa_calculation array BFACTOR_ASA
  CloseSubFrame
 }
