# =======================================================================
# phaser_NMA.tcl --
#
# Phaser Model Generation (NMA)
#
# CCP4Interface
#
# =======================================================================

#------------------------------------------------------------------------------
proc phaser_NMA_prereq { } {
#------------------------------------------------------------------------------
  if { ![file exists [FindExecutable phaser]] } {
    return 0
  }
  return 1
}

#------------------------------------------------------------------------
  proc phaser_NMA_setup { typedefVar arrayname } {
#------------------------------------------------------------------------
  upvar #0 $typedefVar typedef
  upvar #0 $arrayname array

  DefineMenu _mode_menu [list "SCEDS domain division" \
                              "Perturb coordinates" ] \
                        [list "DOMAIN" \
                              "PERTURB" ]

  DefineMenu _eigen_type \
    [list "Write to file" "Do not write to file" "Read from file"] \
    [list "WRITEON" "WRITEOFF" "READ"] 

  DefineMenu _perturb_type \
    [list "  RMS  " "  DQ   " ] [list "RMS" "DQ"]

  DefineMenu _method_type \
    [list "rotation-translation blocks" "C-alpha atoms only" "All atoms" ] \
    [list "RTB" "CA" "ALL" ]

  DefineMenu _perturb_dir \
    [list "forward" "backward" "to-and-fro" ] [list "FORWARD" "BACKWARD" "TOFRO"]

  set typedef(_onoff) \
    { menu { "on" "off" } { ON OFF } }

  DefineMenu _rmsid_option \
   [list "rms difference" "sequence identity" ] [list "RMS" "IDENT" ]

  set typedef(_mat_file) { file MATRIX ".mat" "Phaser matrix file" { "Text Browser" } { DisplayTextFile } }

  return 1
  }

#------------------------------------------------------------------------
proc phaser_NMA_run { arrayname } {
#------------------------------------------------------------------------
  upvar #0 $arrayname array

  set array(OUTPUT_FILES) ""

  if { $array(NMA_XYZIN) == "" } {
     WarningMessage "NOT SET: pdb file"
     return 0
  }
  if { $array(ENSEMBLE_ID_NMA) == "" } {
     WarningMessage "NOT SET: ensemble name for SOL file output"
     return 0
  }
  if { $array(RMS_NMA) == "" } {
     WarningMessage "NOT SET: sequence identity or RMS deviation for SOL file output"
     return 0
  }
  if { ([GetValue $arrayname NMA_EIGEN] == "READ") && $array(EIGENIN) == "" } {
     WarningMessage "NOT SET: eigen file"
     return 0
  }
  if { $array(N_NMA_MODES) == 0 } {
     WarningMessage "NOT SET: modes for perturbation"
     return 0
  }
  for { set n 1 } { $n <= $array(N_NMA_MODES) } { incr n } {
    if { $array(NMA_MODE,$n) == "" } {
     WarningMessage "NOT SET: normal mode perturbation value"
     return 0
    }
  }
  if { ([GetValue $arrayname NMA_METHOD] == "RTB") } {
  if { $array(TOG_NMA_MAXB) && $array(NMA_MAXB) == "" } {
     WarningMessage "NOT SET: Maximum number of blocks"
     return 0
  }
  if { $array(TOG_NMA_NRES) && $array(NMA_NRES) == "" } {
     WarningMessage "NOT SET: Number of residues per block"
     return 0
  }
  }
  if { ([GetValue $arrayname NMA_PERTURB] == "DQ") } {
  if { $array(N_NMA_DQ) == 0 } {
     WarningMessage "NOT SET: DQ steps"
     return 0
  }
  }
  if { ([GetValue $arrayname NMA_PERTURB] == "DQ") } {
  for { set n 1 } { $n <= $array(N_NMA_DQ) } { incr n } {
    if { $array(NMA_DQ,$n) == "" } {
     WarningMessage "NOT SET: normal mode dq"
     return 0
    }
  }
  }
  if {([GetValue $arrayname NMA_PERTURB] == "RMS")} {
  if { $array(NMA_RMSINC) == "" } {
     WarningMessage "NOT SET: RMS step"
     return 0
  }
  if { $array(NMA_MAXRMS) == "" } {
     WarningMessage "NOT SET: Max RMS distance"
     return 0
  }
  if { $array(TOG_NMA_CLASH) && $array(TOG_NMA_CLASH) == "" } {
     WarningMessage "NOT SET: Clash distance between atoms"
     return 0
  }
  if { $array(TOG_NMA_STRETCH) && $array(TOG_NMA_STRETCH) == "" } {
     WarningMessage "NOT SET: Stretch distance between atoms"
     return 0
  }
  }
  if { $array(TOG_NMA_FORCE) && $array(NMA_FORCE) == "" } {
     WarningMessage "NOT SET: Elastic Network Model force constant"
     return 0
  }
  if { $array(TOG_NMA_RADIUS) && $array(NMA_RADIUS) == "" } {
     WarningMessage "NOT SET: Elastic Network Model interaction radius"
     return 0
  }
  if { $array(TOG_NMA_COMBINATION) && $array(NMA_NCOMB) == "" } {
     WarningMessage "NOT SET: Number of modes to combine at a time"
     return 0
  }

  set array(INPUT_FILES) "NMA_XYZIN"
    if { ([GetValue $arrayname NMA_EIGEN] == "READ") } {
      append array(INPUT_FILES) " EIGENIN"
  }
  return 1
  }

#------------------------------------------------------------------------
 proc phaser_NMA_dq_list { arrayname counter_dqs } {
#------------------------------------------------------------------------
# The auto search extending frame code for adding dqs
  upvar #0 $arrayname array
  CreateLine line \
      label "    " \
      label "Perturb with DQ " widget NMA_DQ -oblig
  }
 
#------------------------------------------------------------------------
 proc phaser_NMA_mode_list { arrayname counter_modes } {
#------------------------------------------------------------------------
# The auto search extending frame code for adding modes
  upvar #0 $arrayname array
  CreateLine line \
      label "Perturb along mode " widget NMA_MODE -oblig 
  }

#------------------------------------------------------------------------
  proc phaser_NMA_task_window {arrayname} {
#------------------------------------------------------------------------

  upvar #0 $arrayname array
#  global configure

  if { [CreateTaskWindow $arrayname \
        "Normal Mode Analysis"\
        "Phaser" \
        [ list "Define data" \
               "Define modes" \
               "Define SCEDS parameters" \
               "Define perturbations" \
               "Output control" \
               "Expert DDM parameters" \
               "Expert ENM parameters" ] ] == 0 } return

# SetProgramHelpFile phaser

#=PROTOCOL===============================================================

  OpenFolder protocol

  CreateTitleLine line TITLE

  CreateLine line \
      label "Mode for normal mode analysis" \
      message "Select the aim of the NMA" \
      widget NMA_DOMAIN

  CreateLine line \
      message "Number of processors (parallelization)" \
      widget TOG_NJOBS -toggleon \
      label "Number of processors "\
      widget NJOBS \
      label "(only relevant if phaser compiled with openmp option)"


#=FILES==================================================================
# The "Define data" folder for Normal Mode Analysis

  OpenFolder 1 open

  CreateInputFileLine line \
      "Select a PDB file" \
      "PDB file" \
      NMA_XYZIN DIR_NMA_XYZIN

#========================================================================
# The "Define modes" folder for Normal Mode Analysis

  OpenFolder 2 open

  CreateLine line \
      label "Note: Mode 7 is the lowest non-trivial mode (after the 3 rotation and 3 translation modes)" -italic

  CreateLine line \
      label "Note: Mode n < 7 is taken to mean the first n modes starting at mode 7 (e.g. 5=7,8,9,10,11)" -italic

  CreateExtendingFrame N_NMA_MODES phaser_NMA_mode_list \
      "Perturb along mode" \
      "Add a mode for perturbation" \
      [list NMA_MODE]

  CreateLine line \
      widget TOG_NMA_COMBINATION -toggleon \
      label "Number of modes to combine at a time" \
      widget NMA_NCOMB
 
#========================================================================
# The "Define SCEDS parameters" folder for Normal Mode Analysis

  OpenFolder 3 NMA_DOMAIN hide [list PERTURB ] open 

  CreateLine line \
      message "Number of domains into which to split the protein" \
      widget TOG_NMA_NUMB -toggleon label "Split PDB file into" widget NMA_NUMB label "domains" \
      toggle_display NMA_DOMAIN open DOMAIN

  CreateLine line \
      message "Use the Equality condition to score domains" \
      widget TOG_NMA_WEIG -toggleon \
      label "SCEDS Weights: Sphericity " widget NMA_WEIG_SPHE -width 5 \
      label "Continutity " widget NMA_WEIG_CONT -width 5 \
      label "Equality " widget NMA_WEIG_EQUA -width 5 \
      label "Density " widget NMA_WEIG_DENS -width 5 \
      toggle_display NMA_DOMAIN open DOMAIN
 
#========================================================================
# The "Perturbation parameters" folder for Normal Mode Analysis

  OpenFolder 4 NMA_DOMAIN hide [list DOMAIN ] open 

  CreateLine line \
      label "Perturb structure in " widget NMA_PERTURB \
      label "steps" 

  CreateLine line \
      label "    " \
      message "RMS deviation step size" \
      label "RMS step" widget NMA_RMSINC \
      label "Max RMS distance" widget NMA_MAXRMS \
      label "Direction" widget NMA_DIRECTION \
      toggle_display NMA_PERTURB open RMS 

  CreateLine line \
      label "    " \
      widget TOG_NMA_CLASH -toggleon \
      label "Perturbation stops when any two atoms come within" widget NMA_CLASH \
      label "Angstroms" \
      toggle_display NMA_PERTURB open RMS 

  CreateLine line \
      label "    " \
      widget TOG_NMA_STRETCH -toggleon \
      label "Perturbation stops when a bond stretches past" widget NMA_STRETCH \
      label "Angstroms" \
      toggle_display NMA_PERTURB open RMS 
  
  OpenSubFrame frame -toggle_display NMA_PERTURB open [list DQ ] hide

  CreateExtendingFrame N_NMA_DQ phaser_NMA_dq_list \
      "Perturb with dq" \
      "List DQ steps explicitly" \
      [list NMA_DQ] 

  CloseSubFrame

#
#========================================================================
# The "Output control" folder for Normal Mode Analysis

  OpenFolder 5 closed

  CreateLine line \
      message "Controls output of PDB files containing potential solutions.\
               Default depends on mode." \
      widget TOG_XYZOUT -toggleon \
      label "PDB file output" \
      widget XYZOUT_ONOFF

  CreateLine line \
      message "For output sol file" \
      label "Ensemble ID" -italic \
      widget ENSEMBLE_ID_NMA

  CreateLine line \
      message "For output sol file" \
      label "Similarity of output PDB files to target structure" -italic \
      widget ENSEMBLE_RMSID_OPTION_NMA \
      widget RMS_NMA -oblig
      
  CreateLine line \
      message "VERBOSE: more information included in log file than by default" \
      widget TOG_VERBOSE \
      label "Verbose output to log file" \

  CreateLine line \
      message "DEBUG: debugging information included in log file than by default" \
      widget TOG_VERBOSE_EXTRA \
      label "Debug output to log file" 

  CreateLine line \
      widget TOG_NMA_EIGEN -toggleon\
      label "Eigenvalues and Eigenvectors" \
      message "Read or Write Eigenvalues and Eigenvectors" \
      widget NMA_EIGEN 

  CreateInputFileLine line \
      "Eigen File input MUST have been generated with an identical NMA Method" \
      "Eigen File" \
      EIGENIN DIR_EIGENIN \
      -toggle_display NMA_EIGEN open READ hide

#========================================================================
# The "Expert DDM parameters" folder for Normal Mode Analysis

  OpenFolder 6 NMA_DOMAIN hide [list PERTURB ] closed 

  CreateLine line \
      message "Control the parameters for domain assignments" \
      widget TOG_NMA_DDM -toggleon \
      label "DDM Distances: " \
      label "Min " widget NMA_DDM_MIN \
      label "Max " widget NMA_DDM_MAX \
      label "Step " widget NMA_DDM_STEP

  CreateLine line \
      message "Control the parameters for domain assignments" \
      widget TOG_NMA_SLI -toggleon \
      label "DDM Slider: " \
      label "Slider " widget NMA_DDM_SLID

  CreateLine line \
      message "Control the parameters for domain assignments" \
      widget TOG_NMA_DIST -toggleon \
      label "DDM through-space separation (Angstroms): " \
      label "Min " widget NMA_DIST_MIN \
      label "Max " widget NMA_DIST_MAX

  CreateLine line \
      message "Control the parameters for domain assignments" \
      widget TOG_NMA_SEQU -toggleon \
      label "DDM sequence separation: " \
      label "Min " widget NMA_SEQU_MIN \
      label "Max " widget NMA_SEQU_MAX

  CreateLine line \
      message "Control the parameters for domain assignments" \
            "(negative: use length dependent defaults)" \
      widget TOG_NMA_JOIN -toggleon \
      label "Sequence Joining Length: " \
      label "Min " widget NMA_JOIN_MIN \
      label "Max " widget NMA_JOIN_MAX

#========================================================================
# The "Expert ENM parameters" folder for Normal Mode Analysis

  OpenFolder 7 closed

  CreateLine line \
      message "Controls NMA method" \
      widget TOG_NMA_METHOD -toggleon \
      label "Elastic Network Model" \
      widget NMA_METHOD  

  CreateLine line \
      label "    " \
      widget TOG_NMA_NRES -toggleon \
      label "Number of residues per block" \
      widget NMA_NRES  \
      toggle_display NMA_METHOD open RTB hide

  CreateLine line \
      label "    " \
      widget TOG_NMA_MAXB -toggleon \
      label "Maximum number of blocks" \
      widget NMA_MAXB \
      toggle_display NMA_METHOD open RTB hide
  CreateLine line \
      widget TOG_NMA_FORCE -toggleon \
      label "Elastic Network Model force constant" widget NMA_FORCE 

  CreateLine line \
      widget TOG_NMA_RADIUS -toggleon \
      label "Elastic Network Model interaction radius" widget NMA_RADIUS label "Angstroms" 

  }
