# ======================================================================
# sequins.tcl --
#
# CCP4Interface 
#
# =======================================================================

#------------------------------------------------------------------------------
proc sequins_prereq { } {
#------------------------------------------------------------------------------
  if { ![file exists [FindExecutable csequins]] } {
    return 0
  }
  return 1
}

#------------------------------------------------------------------------
proc sequins_setup { typedefname arrayname }  {
#------------------------------------------------------------------------

  upvar #0 $typedefname typedef

  set typedef(_ref_structureid) { menu { "1tqw" "1ajr" } }

  return 1
}

#------------------------------------------------------------------------------
proc sequins_run { arrayname } {
#------------------------------------------------------------------------------
  upvar #0 $arrayname array

  global env

  if { $array(REFUSER) == 0 } {
    set base "$env(CLIBD)/reference_structures"
    set code "$array(REFCODE)"
    set array(HKLINref) "$base/reference-$code.mtz"
    set array(XYZINref) "$base/reference-$code.pdb"
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
proc sequins_task_window { arrayname } {
#---------------------------------------------------------------------
  upvar #0 $arrayname array

  if { [ CreateTaskWindow $arrayname  \
	     "Sequence validation using Sequins" "Sequins" \
	     [ list \
	       "Options" \
	      ] ] == 0 } return

# Set the name of the CCP4 program help file to use
  SetProgramHelpFile "csequins"

#=PROTOCOL==============================================================

  OpenFolder protocol 

  CreateTitleLine line TITLE

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
      "Enter input pdb file name for (solved) reference structure" \
      "Reference PDB in" \
      XYZINref DIR_XYZINref

  CreateInputFileLine line \
      "Enter input MTZ file name for (solved) reference structure" \
      "Reference MTZ in" \
      HKLINref DIR_HKLINref \

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
      "Enter input coordinate file name for (unsolved) work structure" \
      "Work PDB in" \
      XYZINwrk DIR_XYZINwrk
  
  CreateInputFileLine line \
      "Enter input reflection file name for (unsolved) work structure" \
      "Work MTZ in" \
      HKLINwrk DIR_HKLINwrk

  CreateLabinLine line \
      "Observed amplitude (FP) and obligatory sigma (SIGFP)" \
      HKLINwrk "FP"  FPwrk     [list FP    FP.F_sigF.F   ] \
      -sigma "SIGFP" SIGFPwrk  [list SIGFP FP.F_sigF.sigF]

  OpenSubFrame refin \
      -toggle_display USEWRKHL open 1

  CreateLabinLine4 line \
      "Choose Hendrickson-Lattman coefficients from phase improvement (i.e. DENSITY MODIFIED PHASES)" \
      HKLINwrk     "HLA" HLAwrk  [list pirate.ABCD.A HLA] \
      -dependent   "HLB" HLBwrk  [list pirate.ABCD.B HLB] \
      -dependent   "HLC" HLCwrk  [list pirate.ABCD.C HLC] \
      -dependent   "HLD" HLDwrk  [list pirate.ABCD.D HLD]

  CloseSubFrame

  CreateLine line \
      message "Unbiased experimental phasing increases reliability" \
      label "Use experimental phasing: " \
      widget USEWRKHL

#-----------------------------------------------------

  OpenFolder 1 open

  CreateLine line \
      message "Reduces bias, but requires good data - if in doubt, try both" \
      help side-chain-omit \
      label "Use side-chain omit map: " \
      widget USEOMIT -width 4

  CreateLine line \
      message "Changes the scoring function - if in doubt, try both" \
      help correlation-mode \
      label "Use correlation target function: " \
      widget USECORR -width 4

  CreateLine line \
      message "Using data beyond 1.75A is slow and seldom helps." \
      help resolution \
      label "Maximum data resolution to use in map calculation:" \
      widget RESOLUTION_MAX -width 4

  CreateLine line \
      message "The default is a good choice." \
      label "Library reference structure to use: " \
      widget REFCODE \
      label " (unless user-defined)."
}
