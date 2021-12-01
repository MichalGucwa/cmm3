# ======================================================================
# pirate.tcl --
#
# CCP4Interface 
#
# =======================================================================

#------------------------------------------------------------------------------
proc pirate_prereq { } {
#------------------------------------------------------------------------------
  if { ![file exists [FindExecutable cpirate]] } {
    return 0
  }
  return 1
}

#------------------------------------------------------------------------------
proc pirate_run { arrayname } {
#------------------------------------------------------------------------------
  upvar #0 $arrayname array

  global env

  if { $array(REFUSER) == 0 } {
    set base [FileJoin [GetEnvPath CLIBD] reference_structures]
    set code "$array(REFCODE)"
    set array(HKLINref) [FileJoin $base reference-$code.mtz]
    set array(FPref)    "FP.F_sigF.F"
    set array(SIGFPref) "FP.F_sigF.sigF"
    set array(HLAref)   "FC.ABCD.A"
    set array(HLBref)   "FC.ABCD.B"
    set array(HLCref)   "FC.ABCD.C"
    set array(HLDref)   "FC.ABCD.D"
  }

  return 1
}

#---------------------------------------------------------------------
proc pirate_task_window { arrayname } {
#---------------------------------------------------------------------
  upvar #0 $arrayname array

  if { [ CreateTaskWindow $arrayname  \
	     "Phase improvement using Pirate" "Pirate" \
	     [ list \
	       "Options" \
	       "Likelihood Weighting and Bias" \
	       "Other options" \
	      ] ] == 0 } return

# Set the name of the CCP4 program help file to use
  SetProgramHelpFile "cpirate"

#=PROTOCOL==============================================================

  OpenFolder protocol 

  CreateTitleLine line TITLE

  CreateLine line \
      message "Use NCS relationships from heavy atoms for phase improvement" \
      widget NCSHA -width 4 \
      label "Use Non-crystallographic symmetry (NCS)."

#=FILES================================================================

  OpenFolder file 

  CreateLine line \
      label "Data for (solved) reference structure" -italic

  CreateLine line \
      message "Select this if you want to use your own reference structure data for an unusual problem." \
      widget REFUSER -width 4 \
      label "Specify a user-defined reference structure instead of the standard library."

  OpenSubFrame refin \
      -toggle_display REFUSER open 1

  CreateInputFileLine line \
      "Enter input MTZ file name for (solved) reference structure" \
      "Reference MTZ in" \
      HKLINref DIR_HKLINref

  CreateLabinLine line \
      "Observed amplitude (FP) and obligatory sigma (SIGFP)" \
      HKLINref "FP"  FPref     [list FP.F_sigF.F    FP   ] \
      -sigma "SIGFP" SIGFPref  [list FP.F_sigF.sigF SIGFP]

  CreateLabinLine4 line \
      "Choose Hendrickson-Lattman coefficients from final model" \
      HKLINref     "HLA" HLAref  [list FC.ABCD.A HLA] \
      -dependent   "HLB" HLBref  [list FC.ABCD.B HLB] \
      -dependent   "HLC" HLCref  [list FC.ABCD.C HLC] \
      -dependent   "HLD" HLDref  [list FC.ABCD.D HLD]

  CloseSubFrame

  CreateLine line \
      label "Data for (unsolved) work structure" -italic

  CreateInputFileLine line \
      "Enter input MTZ file name for (unsolved) work structure" \
      "Work MTZ in" \
      HKLINwrk DIR_HKLINwrk \
      -fileout HKLOUT DIR_HKLOUT "_pirate"

  CreateLabinLine line \
      "Observed amplitude (FP) and obligatory sigma (SIGFP)" \
      HKLINwrk "FP"  FPwrk     [list FP    FP.F_sigF.F   ] \
      -sigma "SIGFP" SIGFPwrk  [list SIGFP FP.F_sigF.sigF]

  CreateLabinLine4 line \
      "Choose Hendrickson-Lattman coefficients from phasing" \
      HKLINwrk     "HLA" HLAwrk  [list HLA FC.ABCD.A] \
      -dependent   "HLB" HLBwrk  [list HLB FC.ABCD.B] \
      -dependent   "HLC" HLCwrk  [list HLC FC.ABCD.C] \
      -dependent   "HLD" HLDwrk  [list HLD FC.ABCD.D]

  CreateLabinLine line \
      "Choose Free-R flag" \
      HKLINwrk "Free-R flag" FREEwrk  [list FreeR_flag]

  OpenSubFrame pdbinha \
      -toggle_display NCSHA open 1

  CreateInputFileLine line \
    "Enter input heavy-atom PDB file name" \
    "Heavy atom PDB file" \
     PDBINha DIR_PDBINha

  CloseSubFrame

  CreateOutputFileLine line \
      "Output MTZ File for results" \
      "Work MTZ out" \
      HKLOUT DIR_HKLOUT

  CreateLine line \
      message "Output column label prefix (colout)" \
      help colout \
      label "Output column label prefix" \
      widget COLOUT -width 12

#-----------------------------------------------------

  OpenFolder 1 open

  CreateLine line \
      message "Automatically adjust the content of the unit cell (auto-content)" \
      help auto-content \
      widget AUTOCONT -width 4 \
      label "Perform automatic cell content estimation." \
      label " Matches reference structure cell content to work." -italic

  CreateLine line \
      message "Positive values increase specified region of reference, negative decrease. (-1.0...1.0)" \
      help evaluate \
      label "  Skew content of:" \
      label " Dense regions" \
      widget SKEWCONT1 -width 4 \
      label " Ordered regions" \
      widget SKEWCONT2 -width 4 \
      label " +ve to increase region, -ve to decrease." -italic \
      toggle_display AUTOCONT open 0

  CreateLine line \
      message "Automatically weight the histogram data" \
      help auto-mapllk \
      widget AUTOMAPW -width 4 \
      label "Perform automatic weighting of non-ncs phase information." \
      label " Try changing this only if resulting map is poor." -italic

  CreateLine line \
      message "Weight for map likelihood (weight-mapllk)" \
      help weight-mapllk \
      label "Weight for map likelihood:" \
      widget WTMAPLLK -width 4 \
      toggle_display AUTOMAPW open 0

  OpenSubFrame frame \
      -toggle_display NCSHA open 1

  CreateLine line \
      message "Automatically weight the ncs data" \
      help auto-ncsllk \
      widget AUTONCSW -width 4 \
      label "Perform automatic weighting of ncs phase information." \
      label " Try changing this only if resulting map is poor." -italic

  CreateLine line \
      message "Weight for ncs likelihood (weight-ncsllk)" \
      help weight-ncsllk \
      label "Weight for ncs likelihood:" \
      widget WTNCSLLK -width 4 \
      toggle_display AUTONCSW open 0

  CreateLine line \
      message "Select this if you have high order mixed non-crystallographic and crystallographic symmetry" \
      label "NCS virus mode" \
      widget NCSVIRUS -width 4 \
      label " Select this to look for huge NCS related regions." -italic

  CloseSubFrame

#-----------------------------------------------------

  OpenFolder 2 closed

  CreateLine line \
      message "Use unbias mode to remove bias (biasmode)" \
      help biasmode \
      widget UNBIAS -width 4 \
      label "Use unbias mode to remove bias:" \
      label " Useful for molecular replacement." -italic

  CreateLine line \
      message "Use strict Free-R over multiple cycles (strict-free)" \
      help strict-free \
      widget STRICTFR -width 4 \
      label "Use strict Free-R throughout:" \
      label " Use this only if refining against output phases." -italic

  CreateLine line \
      message "Weight to correct distributions from phasing (weight-expllk)" \
      help weight-expllk \
      label "Weight for input phasing: " \
      widget WTEXPLLK -width 4 \
      label " Use this to correct for flaws in phasing programs." -italic

#-----------------------------------------------------

  OpenFolder 3 closed

  CreateLine line \
      message "Use evaluation mode to evaluate test structures (evaluate)" \
      help evaluate \
      widget EVALUATE -width 4 \
      label "Use evaluation mode." \
      label " Does a quick calculation with no output for evaluation of settings." -italic

  CreateLine line \
      message "Number of cycles of refinement (ncycles)" \
      help ncycles \
      label "Number of cycles:" \
      widget NCYCLES -width 3 \
      label " Should not make much difference." -italic

  CreateLine line \
      message "Local map filter radius (radius)" \
      help radius \
      label "Local map filter radius:" \
      label " Initial cycle" \
      widget RADIUS1 -width 4 \
      label " Final cycle" \
      widget RADIUS2 -width 4 \
      label " The default values are good for most tasks." -italic

}

