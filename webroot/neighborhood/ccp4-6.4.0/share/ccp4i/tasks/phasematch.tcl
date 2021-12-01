# ======================================================================
# phasematch.tcl --
#
# CCP4Interface 
#
# =======================================================================
#------------------------------------------------------------------------------
proc phasematch_prereq { } {
#------------------------------------------------------------------------------
  if { ![file exists [FindExecutable cphasematch]] } {
    return 0
  }
  return 1
}
#------------------------------------------------------------------------
proc phasematch_setup { typedefname arrayname }  {
#------------------------------------------------------------------------

  upvar #0 $typedefname typedef

  set typedef(_phasematch_coeff) { menu { "Map coefficients (F/phi)" \
					      "HL coefficients (ABCD)" \
					      "Phase/weight (phi/fom)" \
					  } { MAPCOEFF HLCOEFF PWCOEFF } }
  return 1
}

#---------------------------------------------------------------------
proc phasematch_task_window { arrayname } {
#---------------------------------------------------------------------
  upvar #0 $arrayname array

  if { [ CreateTaskWindow $arrayname  \
	     "Phase comparison and origin/hand matching" "phasematch" \
	     [ list \
	       "Options" \
	      ] ] == 0 } return

# Set the name of the CCP4 program help file to use
  SetProgramHelpFile "cphasematch"

#=PROTOCOL==============================================================

  OpenFolder protocol 

  CreateTitleLine line TITLE

  CreateLine line  \
        widget MODEMATCH \
        message "Choose whether to match origin and hand."  \
        label "Match origin and hand before comparison"

#=FILES================================================================

  OpenFolder file 

  CreateInputFileLine line \
      "Enter input MTZ file name" \
      "MTZ in" \
      HKLIN DIR_HKLIN \
      -fileout HKLOUT DIR_HKLOUT "_phasematch"

  CreateLabinLine line \
      "Observed amplitude (FP) and obligatory sigma (SIGFP)" \
      HKLIN  "FP"    FP     [list FP FP.F_sigF.F] \
      -sigma "SIGFP" SIGFP  [list FP FP.F_sigF.sigF]

  CreateLine line  \
        message "Choose the type of input reflection data to use."  \
        label "First set of phases from:" \
        widget MODECOEFF1

  CreateLabinLine line \
      "Choose F/phi" \
      HKLIN    "F"   FMAP1    [list pirate.F_phi.F   FWT] \
      -sigma   "PHI" PHIMAP1  [list pirate.F_phi.phi PHWT] \
      -toggle_display MODECOEFF1 open MAPCOEFF

  CreateLabinLine4 line \
      "Choose Hendrickson-Lattman coefficients from phasing" \
      HKLIN      "HLA" HLA1  [list HLA obs.ABCD.A] \
      -dependent "HLB" HLB1  [list HLB obs.ABCD.B] \
      -dependent "HLC" HLC1  [list HLC obs.ABCD.C] \
      -dependent "HLD" HLD1  [list HLD obs.ABCD.D] \
      -toggle_display MODECOEFF1 open HLCOEFF

  CreateLabinLine line \
      "Choose phi/fom" \
      HKLIN    "PHI" PHI1  [list PHIB Fobs.Phi_fom.phi] \
      -sigma   "FOM" FOM1  [list FOM  Fobs.Phi_fom.fom] \
      -toggle_display MODECOEFF1 open PWCOEFF

  CreateLine line  \
        message "Choose the type of input reflection data to use."  \
        label "Second set of phases from:" \
        widget MODECOEFF2

  CreateLabinLine line \
      "Choose F/phi" \
      HKLIN    "F"   FMAP2    [list pirate.F_phi.F   FWT] \
      -sigma   "PHI" PHIMAP2  [list pirate.F_phi.phi PHWT] \
      -toggle_display MODECOEFF2 open MAPCOEFF

  CreateLabinLine4 line \
      "Choose Hendrickson-Lattman coefficients from phasing" \
      HKLIN      "HLA" HLA2  [list HLA obs.ABCD.A] \
      -dependent "HLB" HLB2  [list HLB obs.ABCD.B] \
      -dependent "HLC" HLC2  [list HLC obs.ABCD.C] \
      -dependent "HLD" HLD2  [list HLD obs.ABCD.D] \
      -toggle_display MODECOEFF2 open HLCOEFF

  CreateLabinLine line \
      "Choose phi/fom" \
      HKLIN    "PHI" PHI2  [list PHIB Fobs.Phi_fom.phi] \
      -sigma   "FOM" FOM2  [list FOM  Fobs.Phi_fom.fom] \
      -toggle_display MODECOEFF2 open PWCOEFF

  OpenSubFrame frame \
      -toggle_display MODEMATCH open 1

  CreateLine line \
      label "Output MTZ file has origin/hand phase shifts applied to the second set of phases:"

  CreateOutputFileLine line \
      "Enter output MTZ file name" \
      "MTZ out" \
      HKLOUT DIR_HKLOUT

  CreateLine line \
        message "Output column label prefix (colout)" \
        help colout \
        label "Output column label prefix" \
        widget COLOUT -width 12

  CloseSubFrame

#-----------------------------------------------------

  OpenFolder 1 closed

  CreateLine line \
      message "Number of resolution shells for statistics" \
      help resolution-bins \
      label "Number of resolution bins" \
      widget NRESBINS

}

